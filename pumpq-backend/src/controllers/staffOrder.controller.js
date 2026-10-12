const supabase = require('../config/supabase');
const admin = require('../config/firebaseAdmin');
const ok = (res, status, data, message) => res.status(status).json({ success: true, data, message });
const fail = (res, status, message) => res.status(status).json({ success: false, data: null, message });

async function myStationId(req) {
  const { data } = await supabase.from('staff').select('station_id').eq('staff_id', req.staffId).maybeSingle();
  return data?.station_id;
}

async function listOrders(req, res) {
  const station_id = await myStationId(req);
  const { data, error } = await supabase
    .from('order')
    .select('order_id, user_id, fuel_type, liters, amount, status, payment_status, created_at')
    .eq('station_id', station_id)
    .order('created_at', { ascending: false });
  if (error) return fail(res, 500, 'Server error');
  return ok(res, 200, { orders: data }, 'OK');
}

async function acceptOrder(req, res) {
  const { data: order, error } = await supabase
    .from('order')
    .select('order_id, user_id, status, liters, fuel_type, amount')
    .eq('order_id', req.params.id)
    .maybeSingle();
  if (error) return fail(res, 500, 'Server error');
  if (!order) return fail(res, 404, 'Order not found');
  if (order.status !== 'pending') return fail(res, 409, `Order is already ${order.status}`);

  const { data: confirmed, error: upErr } = await supabase
    .from('order')
    .update({ status: 'completed' })
    .eq('order_id', order.order_id)
    .select()
    .single();
  if (upErr) return fail(res, 500, 'Could not confirm order');

  // Credit loyalty points (1 per liter) — same logic as mobile QR flow.
  const points = Math.floor(order.liters);
  if (points > 0) {
    let { data: account } = await supabase.from('loyalty_account').select('*').eq('user_id', order.user_id).maybeSingle();
    if (!account) {
      const { data: created } = await supabase.from('loyalty_account').insert({ user_id: order.user_id, points_balance: 0, tier: 'Bronze', streak_count: 0 }).select().single();
      account = created;
    }
    const newBalance = account.points_balance + points;
    const tier = newBalance >= 1500 ? 'Gold' : newBalance >= 500 ? 'Silver' : 'Bronze';
    await supabase.from('loyalty_account').update({ points_balance: newBalance, tier, streak_count: account.streak_count + 1 }).eq('loyalty_id', account.loyalty_id);
    await supabase.from('loyalty_transaction').insert({ loyalty_id: account.loyalty_id, order_id: order.order_id, points_earned: points, points_redeemed: 0 });
  }

  // Notify customer, if they have a device token.
  try {
    const { data: user } = await supabase.from('user').select('fcm_token').eq('user_id', order.user_id).maybeSingle();
    if (user?.fcm_token) {
      await admin.messaging().send({
        token: user.fcm_token,
        notification: { title: 'Order Confirmed!', body: `Your ${order.liters}L ${order.fuel_type} order has been fulfilled.` },
      });
    }
  } catch (e) { console.error('Push failed:', e); }

  return ok(res, 200, { order: confirmed }, 'Order accepted');
}

async function cancelOrder(req, res) {
  const { data: order } = await supabase.from('order').select('status').eq('order_id', req.params.id).maybeSingle();
  if (!order) return fail(res, 404, 'Order not found');
  if (order.status !== 'pending') return fail(res, 409, `Order is already ${order.status}`);
  const { data, error } = await supabase.from('order').update({ status: 'cancelled' }).eq('order_id', req.params.id).select().single();
  if (error) return fail(res, 500, 'Could not cancel');
  return ok(res, 200, { order: data }, 'Order cancelled');
}

module.exports = { listOrders, acceptOrder, cancelOrder };