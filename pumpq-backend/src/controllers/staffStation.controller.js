const supabase = require('../config/supabase');
const ok = (res, status, data, message) => res.status(status).json({ success: true, data, message });
const fail = (res, status, message) => res.status(status).json({ success: false, data: null, message });

async function listAllStations(req, res) {
  const { data, error } = await supabase.from('gas_station').select('*');
  if (error) return fail(res, 500, 'Server error');
  return ok(res, 200, { stations: data }, 'OK');
}

async function compareAllPrices(req, res) {
  const { data, error } = await supabase
    .from('fuel_posting')
    .select('price_id, station_id, fuel_type, price, availability, gas_station(name, fuel_brand)');
  if (error) return fail(res, 500, 'Server error');
  const prices = data.map((r) => ({
    price_id: r.price_id, station_id: r.station_id, fuel_type: r.fuel_type,
    price: r.price, availability: r.availability,
    station_name: r.gas_station?.name, fuel_brand: r.gas_station?.fuel_brand,
  }));
  return ok(res, 200, { prices }, 'OK');
}

module.exports = { listAllStations, compareAllPrices };