const supabase = require('../config/supabase');
const admin = require('../config/firebaseAdmin');
const ok = (res, status, data, message) => res.status(status).json({ success: true, data, message });
const fail = (res, status, message) => res.status(status).json({ success: false, data: null, message });

async function sendPriceAlert(station_id, fuel_type, price) {
  try {
    const { data: station } = await supabase.from('gas_station').select('name').eq('station_id', station_id).maybeSingle();
    const stationName = station?.name || 'A nearby station';
    const { data: users } = await supabase.from('user').select('fcm_token').not('fcm_token', 'is', null);
    const tokens = (users || []).map((u) => u.fcm_token).filter(Boolean);
    if (tokens.length > 0) {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: `⛽ Price Update at ${stationName}`,
          body: `${fuel_type} is now ₱${Number(price).toFixed(2)}/L.`,
        },
      });
    }
  } catch (err) {
    console.error('Price alert push error:', err.message);
  }
}

async function listMine(req, res) {
  const { data: staff } = await supabase.from('staff').select('station_id').eq('staff_id', req.staffId).maybeSingle();
  const { data, error } = await supabase.from('fuel_posting').select('*').eq('station_id', staff.station_id);
  if (error) return fail(res, 500, 'Server error');
  return ok(res, 200, { postings: data }, 'OK');
}

async function create(req, res) {
  const { fuel_type, price, availability } = req.body || {};
  if (!fuel_type || price == null) return fail(res, 400, 'fuel_type and price required');
  const { data: staff } = await supabase.from('staff').select('station_id').eq('staff_id', req.staffId).maybeSingle();
  const { data, error } = await supabase
    .from('fuel_posting')
    .insert({ station_id: staff.station_id, fuel_type, price, availability: availability ?? true })
    .select()
    .single();
  if (error) return fail(res, 500, 'Could not create posting');
  sendPriceAlert(staff.station_id, data.fuel_type, data.price).catch(() => {});
  return ok(res, 201, { posting: data }, 'Created');
}

async function update(req, res) {
  const { fuel_type, price, availability } = req.body || {};
  const updates = {};
  if (fuel_type !== undefined) updates.fuel_type = fuel_type;
  if (price !== undefined) updates.price = price;
  if (availability !== undefined) updates.availability = availability;
  const { data, error } = await supabase.from('fuel_posting').update(updates).eq('price_id', req.params.id).select().single();
  if (error) return fail(res, 500, 'Could not update');
  sendPriceAlert(data.station_id, data.fuel_type, data.price).catch(() => {});
  return ok(res, 200, { posting: data }, 'Updated');
}

async function remove(req, res) {
  const { error } = await supabase.from('fuel_posting').delete().eq('price_id', req.params.id);
  if (error) return fail(res, 500, 'Could not delete');
  return ok(res, 200, {}, 'Deleted');
}

module.exports = { listMine, create, update, remove };