const supabase = require('../config/supabase');

const ok = (res, status, data, message) =>
  res.status(status).json({ success: true, data, message });
const fail = (res, status, message) =>
  res.status(status).json({ success: false, data: null, message });

async function listStations(req, res) {
  try {
    const { data: stations, error } = await supabase
      .from('gas_station')
      .select('station_id, name, fuel_brand, location, latitude, longitude, is_open');

    if (error) {
      console.error(error);
      return fail(res, 500, 'Could not fetch stations');
    }
    return ok(res, 200, { stations }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function listFuelPrices(req, res) {
  try {
    const { data, error } = await supabase
      .from('fuel_posting')
      .select('price_id, station_id, fuel_type, price, availability, gas_station(name, fuel_brand)');

    if (error) {
      console.error(error);
      return fail(res, 500, 'Could not fetch fuel prices');
    }

    const prices = data.map((row) => ({
      price_id: row.price_id,
      station_id: row.station_id,
      station_name: row.gas_station?.name,
      fuel_brand: row.gas_station?.fuel_brand,
      fuel_type: row.fuel_type,
      price: row.price,
      availability: row.availability,
    }));

    return ok(res, 200, { prices }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

module.exports = { listStations, listFuelPrices };