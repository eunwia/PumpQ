const supabase = require('../config/supabase');

const ok = (res, status, data, message) => res.status(status).json({ success: true, data, message });
const fail = (res, status, message) => res.status(status).json({ success: false, data: null, message });

async function listPromotions(req, res) {
  try {
    const { data: promotions, error } = await supabase
      .from('promotion')
      .select('promo_id, station_id, promo_name, promo_type, discount_value, promo_tag, coupon_code, expires_at, gas_station(name)')
      .eq('is_active', true)
      .gt('expires_at', new Date().toISOString());

    if (error) {
      console.error(error);
      return fail(res, 500, 'Could not fetch promotions');
    }

    const formatted = promotions.map((p) => ({
      promo_id: p.promo_id,
      station_id: p.station_id,
      station_name: p.gas_station?.name ?? null,
      promo_name: p.promo_name,
      promo_type: p.promo_type,
      discount_value: p.discount_value,
      promo_tag: p.promo_tag,
      coupon_code: p.coupon_code,
      expires_at: p.expires_at,
    }));

    return ok(res, 200, { promotions: formatted }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function applyCoupon(req, res) {
  try {
    const { order_id, coupon_code } = req.body || {};
    if (!order_id || !coupon_code) return fail(res, 400, 'order_id and coupon_code are required');

    const { data: order, error: orderError } = await supabase
      .from('order')
      .select('order_id, user_id, station_id, amount, status, payment_status, promo_id')
      .eq('order_id', order_id)
      .eq('user_id', req.userId)
      .maybeSingle();

    if (orderError) return fail(res, 500, 'Server error');
    if (!order) return fail(res, 404, 'Order not found');
    if (order.status !== 'pending') return fail(res, 409, 'Cannot apply a coupon to a non-pending order');
    if (order.payment_status !== 'unpaid') return fail(res, 409, 'Apply a coupon before paying');
    if (order.promo_id) return fail(res, 409, 'A coupon is already applied to this order');

    const { data: promo, error: promoError } = await supabase
      .from('promotion')
      .select('promo_id, station_id, promo_type, discount_value, expires_at, is_active')
      .eq('coupon_code', coupon_code.toUpperCase())
      .maybeSingle();

    if (promoError) return fail(res, 500, 'Server error');
    if (!promo || !promo.is_active || new Date(promo.expires_at) < new Date()) {
      return fail(res, 404, 'Invalid or expired coupon code');
    }
    if (promo.station_id && promo.station_id !== order.station_id) {
      return fail(res, 400, 'This coupon is not valid at this station');
    }

    const discount =
      promo.promo_type === 'percentage'
        ? Number((order.amount * (promo.discount_value / 100)).toFixed(2))
        : Math.min(promo.discount_value, order.amount);

    const newAmount = Number((order.amount - discount).toFixed(2));

    const { data: updated, error: updateError } = await supabase
      .from('order')
      .update({ amount: newAmount, discount_amount: discount, promo_id: promo.promo_id })
      .eq('order_id', order_id)
      .select('order_id, amount, discount_amount, promo_id')
      .single();

    if (updateError) return fail(res, 500, 'Could not apply coupon');

    return ok(res, 200, { order: updated }, 'Coupon applied');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

module.exports = { listPromotions, applyCoupon };