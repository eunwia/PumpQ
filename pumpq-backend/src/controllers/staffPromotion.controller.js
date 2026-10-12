const supabase = require('../config/supabase');
const ok = (res, status, data, message) => res.status(status).json({ success: true, data, message });
const fail = (res, status, message) => res.status(status).json({ success: false, data: null, message });

async function myStationId(req) {
  const { data } = await supabase.from('staff').select('station_id').eq('staff_id', req.staffId).maybeSingle();
  return data?.station_id;
}

async function list(req, res) {
  const station_id = await myStationId(req);
  const { data, error } = await supabase.from('promotion').select('*').eq('station_id', station_id);
  if (error) return fail(res, 500, 'Server error');
  return ok(res, 200, { promotions: data }, 'OK');
}

async function create(req, res) {
  const { promo_name, promo_type, discount_value, promo_tag, coupon_code, expires_at } = req.body || {};
  if (!promo_name || !promo_type || discount_value == null || !coupon_code) {
    return fail(res, 400, 'promo_name, promo_type, discount_value, coupon_code required');
  }
  const station_id = await myStationId(req);
  const { data, error } = await supabase
    .from('promotion')
    .insert({ station_id, promo_name, promo_type, discount_value, promo_tag, coupon_code: coupon_code.toUpperCase(), expires_at, is_active: true })
    .select()
    .single();
  if (error) return fail(res, error.code === '23505' ? 409 : 500, error.code === '23505' ? 'Coupon code already in use' : 'Could not create');
  return ok(res, 201, { promotion: data }, 'Created');
}

async function update(req, res) {
  const updates = { ...req.body };
  if (updates.coupon_code) updates.coupon_code = updates.coupon_code.toUpperCase();
  const { data, error } = await supabase.from('promotion').update(updates).eq('promo_id', req.params.id).select().single();
  if (error) return fail(res, 500, 'Could not update');
  return ok(res, 200, { promotion: data }, 'Updated');
}

async function remove(req, res) {
  const { error } = await supabase.from('promotion').delete().eq('promo_id', req.params.id);
  if (error) return fail(res, 500, 'Could not delete');
  return ok(res, 200, {}, 'Deleted');
}

module.exports = { list, create, update, remove };