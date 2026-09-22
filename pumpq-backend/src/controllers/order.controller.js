const supabase = require('../config/supabase');

const ok = (res, status, data, message) =>
  res.status(status).json({ success: true, data, message });

const fail = (res, status, message) =>
  res.status(status).json({ success: false, data: null, message });

const ORDER_FIELDS =
  'order_id, user_id, station_id, qr_code, fuel_type, liters, amount, status, scheduled_at, created_at';

async function createOrder(req, res) {
  try {
    const { station_id, fuel_type, liters, scheduled_at } = req.body || {};

    if (!station_id || !fuel_type || !liters) {
      return fail(res, 400, 'station_id, fuel_type and liters are required');
    }
    if (typeof liters !== 'number' || liters <= 0) {
      return fail(res, 400, 'liters must be a positive number');
    }

    // Look up the current price server-side — never trust a price from the client.
    const { data: posting, error: postingError } = await supabase
      .from('fuel_posting')
      .select('price, availability')
      .eq('station_id', station_id)
      .eq('fuel_type', fuel_type)
      .maybeSingle();

    if (postingError) {
      console.error(postingError);
      return fail(res, 500, 'Could not look up fuel price');
    }
    if (!posting) {
      return fail(res, 404, 'This fuel type is not offered at that station');
    }
    if (!posting.availability) {
      return fail(res, 409, 'This fuel type is currently unavailable at that station');
    }

    const amount = Number((posting.price * liters).toFixed(2));

    const { data: order, error } = await supabase
      .from('order')
      .insert({
        user_id: req.userId,
        station_id,
        fuel_type,
        liters,
        amount,
        status: 'pending',
        scheduled_at: scheduled_at || null,
      })
      .select(ORDER_FIELDS)
      .single();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Could not create order');
    }

    return ok(res, 201, { order }, 'Order created');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function listOrders(req, res) {
  try {
    const { data: orders, error } = await supabase
      .from('order')
      .select(ORDER_FIELDS)
      .eq('user_id', req.userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error(error);
      return fail(res, 500, 'Could not fetch orders');
    }

    return ok(res, 200, { orders }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function getOrder(req, res) {
  try {
    const { data: order, error } = await supabase
      .from('order')
      .select(ORDER_FIELDS)
      .eq('order_id', req.params.id)
      .eq('user_id', req.userId)
      .maybeSingle();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Server error');
    }
    if (!order) return fail(res, 404, 'Order not found');

    return ok(res, 200, { order }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function cancelOrder(req, res) {
  try {
    const { data: existing, error: fetchError } = await supabase
      .from('order')
      .select('order_id, status')
      .eq('order_id', req.params.id)
      .eq('user_id', req.userId)
      .maybeSingle();

    if (fetchError) {
      console.error(fetchError);
      return fail(res, 500, 'Server error');
    }
    if (!existing) return fail(res, 404, 'Order not found');
    if (existing.status !== 'pending') {
      return fail(res, 409, `Cannot cancel an order that is already ${existing.status}`);
    }

    const { data: order, error } = await supabase
      .from('order')
      .update({ status: 'cancelled' })
      .eq('order_id', req.params.id)
      .select(ORDER_FIELDS)
      .single();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Could not cancel order');
    }

    return ok(res, 200, { order }, 'Order cancelled');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

module.exports = { createOrder, listOrders, getOrder, cancelOrder };