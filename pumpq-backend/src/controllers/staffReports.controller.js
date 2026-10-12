const supabase = require('../config/supabase');
const ok = (res, status, data, message) => res.status(status).json({ success: true, data, message });
const fail = (res, status, message) => res.status(status).json({ success: false, data: null, message });

async function myStationId(req) {
  const { data } = await supabase.from('staff').select('station_id').eq('staff_id', req.staffId).maybeSingle();
  return data?.station_id;
}

async function salesReport(req, res) {
  const station_id = await myStationId(req);
  const { data: orders, error } = await supabase
    .from('order')
    .select('order_id, amount, liters, fuel_type, status, created_at')
    .eq('station_id', station_id)
    .eq('status', 'completed')
    .order('created_at', { ascending: true });
  if (error) return fail(res, 500, 'Server error');

  const totalRevenue = orders.reduce((s, o) => s + Number(o.amount), 0);
  const totalLiters = orders.reduce((s, o) => s + Number(o.liters), 0);

  const byDay = {};
  for (const o of orders) {
    const day = o.created_at.slice(0, 10);
    byDay[day] = (byDay[day] || 0) + Number(o.amount);
  }

  return ok(res, 200, {
    total_orders: orders.length,
    total_revenue: totalRevenue,
    total_liters: totalLiters,
    by_day: byDay,
    orders,
  }, 'OK');
}

async function aiAnalytics(req, res) {
  const station_id = await myStationId(req);
  const { data: orders, error } = await supabase
    .from('order')
    .select('liters, fuel_type, created_at')
    .eq('station_id', station_id)
    .eq('status', 'completed');
  if (error) return fail(res, 500, 'Server error');

  const byFuelType = {};
  for (const o of orders) byFuelType[o.fuel_type] = (byFuelType[o.fuel_type] || 0) + Number(o.liters);

  const topFuel = Object.entries(byFuelType).sort((a, b) => b[1] - a[1])[0]?.[0] || null;

  return ok(res, 200, { demand_by_fuel_type: byFuelType, top_fuel_type: topFuel, sample_size: orders.length }, 'OK');
}

module.exports = { salesReport, aiAnalytics };