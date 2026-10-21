const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');
const admin = require('../config/firebaseAdmin');

const ok = (res, status, data, message) =>
  res.status(status).json({ success: true, data, message });
const fail = (res, status, message) =>
  res.status(status).json({ success: false, data: null, message });

function generateShortCode() {
  return 'PQ-' + crypto.randomBytes(3).toString('hex').toUpperCase();
}

async function generateQr(req, res) {
  try {
    const { order_id } = req.body || {};
    if (!order_id) return fail(res, 400, 'order_id is required');

    const { data: order, error } = await supabase
      .from('order')
      .select('order_id, status, user_id')
      .eq('order_id', order_id)
      .eq('user_id', req.userId)
      .maybeSingle();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Server error');
    }
    if (!order) return fail(res, 404, 'Order not found');
    if (order.status !== 'pending') {
      return fail(res, 409, `Cannot generate a QR for an order that is ${order.status}`);
    }

    const shortCode = generateShortCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();

    const { data: updated, error: updateError } = await supabase
      .from('order')
      .update({ qr_code: shortCode, scheduled_at: expiresAt })
      .eq('order_id', order_id)
      .select('order_id, user_id, station_id, qr_code, fuel_type, liters, amount, status, scheduled_at, created_at')
      .single();

    if (updateError) {
      console.error(updateError);
      return fail(res, 500, 'Could not generate QR code');
    }

    return ok(res, 200, { order: updated, expires_in_minutes: 15 }, 'QR generated');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function validateQr(req, res) {
  try {
    const { qr_code } = req.body || {};
    if (!qr_code) return fail(res, 400, 'qr_code is required');

    const rawCode = String(qr_code).trim();
    let order;

    // 1. Support legacy long JWT codes (contains dots)
    if (rawCode.includes('.')) {
      let payload;
      try {
        payload = jwt.verify(rawCode, process.env.JWT_SECRET);
      } catch {
        return fail(res, 401, 'QR code is invalid or has expired');
      }
      if (payload.type !== 'order_qr') {
        return fail(res, 400, 'Not a valid order QR code');
      }

      const { data: o, error } = await supabase
        .from('order')
        .select('order_id, user_id, status, qr_code, fuel_type, liters, amount, scheduled_at')
        .eq('order_id', payload.order_id)
        .maybeSingle();

      if (error) {
        console.error(error);
        return fail(res, 500, 'Server error');
      }
      order = o;
    } else {
      // 2. Short code lookup
      const { data: o, error } = await supabase
        .from('order')
        .select('order_id, user_id, status, qr_code, fuel_type, liters, amount, scheduled_at')
        .ilike('qr_code', rawCode)
        .maybeSingle();

      if (error) {
        console.error(error);
        return fail(res, 500, 'Server error');
      }
      order = o;

      if (order && order.scheduled_at) {
        const expiry = new Date(order.scheduled_at).getTime();
        if (Date.now() > expiry) {
          return fail(res, 401, 'QR code is invalid or has expired');
        }
      }
    }

    if (!order) return fail(res, 404, 'Order not found');
    if (order.qr_code && order.qr_code.toLowerCase() !== rawCode.toLowerCase()) {
      return fail(res, 409, 'This QR code has been superseded by a newer one');
    }
    if (order.status !== 'pending') {
      return fail(res, 409, `Order is already ${order.status}`);
    }

    const { data: confirmed, error: updateError } = await supabase
      .from('order')
      .update({ status: 'completed' })
      .eq('order_id', order.order_id)
      .select('order_id, status, fuel_type, liters, amount')
      .single();

    if (updateError) {
      console.error(updateError);
      return fail(res, 500, 'Could not confirm order');
    }

    // Award loyalty points: 1 point per liter, cross-brand.
    const pointsEarned = Math.floor(order.liters);
    await creditLoyaltyPoints(order.user_id, order.order_id, pointsEarned);

        // Send a push notification to the customer, if they have a registered device.
    try {
      const { data: user } = await supabase
        .from('user')
        .select('fcm_token')
        .eq('user_id', order.user_id)
        .maybeSingle();

      if (user?.fcm_token) {
        await admin.messaging().send({
          token: user.fcm_token,
          notification: {
            title: 'Order Confirmed!',
            body: `Your ${order.liters}L ${order.fuel_type} order has been fulfilled. You earned ${pointsEarned} points.`,
          },
        });
      }
    } catch (pushError) {
      console.error('Push notification failed:', pushError);
      // Non-fatal — the order is already confirmed regardless.
    }

    return ok(res, 200, { order: confirmed, points_earned: pointsEarned }, 'Order confirmed');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

function tierForPoints(points) {
  if (points >= 1500) return 'Gold';
  if (points >= 500) return 'Silver';
  return 'Bronze';
}

async function creditLoyaltyPoints(userId, orderId, points) {
  if (points <= 0) return;

  // Get or create the user's loyalty account.
  let { data: account, error } = await supabase
    .from('loyalty_account')
    .select('loyalty_id, points_balance, streak_count')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) {
    console.error('Loyalty lookup failed:', error);
    return;
  }

  if (!account) {
    const { data: created, error: createError } = await supabase
      .from('loyalty_account')
      .insert({ user_id: userId, points_balance: 0, tier: 'Bronze', streak_count: 0 })
      .select('loyalty_id, points_balance, streak_count')
      .single();

    if (createError) {
      console.error('Loyalty account creation failed:', createError);
      return;
    }
    account = created;
  }

  const newBalance = account.points_balance + points;

  const { error: updateError } = await supabase
    .from('loyalty_account')
    .update({
      points_balance: newBalance,
      tier: tierForPoints(newBalance),
      streak_count: account.streak_count + 1,
    })
    .eq('loyalty_id', account.loyalty_id);

  if (updateError) {
    console.error('Loyalty balance update failed:', updateError);
    return;
  }

  const { error: txError } = await supabase.from('loyalty_transaction').insert({
    loyalty_id: account.loyalty_id,
    order_id: orderId,
    points_earned: points,
    points_redeemed: 0,
  });

  if (txError) {
    console.error('Loyalty transaction log failed:', txError);
  }
}
module.exports = { generateQr, validateQr };