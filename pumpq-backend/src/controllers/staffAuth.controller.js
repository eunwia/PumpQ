const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');

const ok = (res, status, data, message) => res.status(status).json({ success: true, data, message });
const fail = (res, status, message) => res.status(status).json({ success: false, data: null, message });

const STAFF_FIELDS = 'staff_id, station_id, first_name, last_name, role, contact_number, email';

function signToken(staffId) {
  return jwt.sign({ type: 'staff' }, process.env.JWT_SECRET, { subject: String(staffId), expiresIn: '7d' });
}

async function register(req, res) {
  try {
    const {
      first_name,
      last_name,
      email,
      password,
      station_id: reqStationId,
      station_name,
      fuel_brand,
      location,
      latitude,
      longitude,
      role,
      contact_number
    } = req.body || {};

    if (!first_name || !last_name || !email || !password) {
      return fail(res, 400, 'first_name, last_name, email, password are required');
    }

    let assignedStationId = reqStationId ? Number(reqStationId) : null;

    // If no station_id was provided, auto-create a gas station from the picked location
    if (!assignedStationId) {
      const rawName = (station_name || location || `${first_name}'s Station`).split(',')[0].trim();
      const name = (rawName || 'Gas Station').slice(0, 100);
      const rawBrand = fuel_brand || (
        /shell/i.test(name) ? 'Shell' :
        /caltex/i.test(name) ? 'Caltex' :
        /petron/i.test(name) ? 'Petron' :
        /seaoil/i.test(name) ? 'Seaoil' :
        /phoenix/i.test(name) ? 'Phoenix' : null
      );
      const detectedBrand = rawBrand ? String(rawBrand).trim().slice(0, 50) : 'PumpQ';
      const rawLocation = location || name || 'Station Location';
      const safeLocation = String(rawLocation).trim().slice(0, 100);

      const { data: newStation, error: stationErr } = await supabase
        .from('gas_station')
        .insert({
          name,
          fuel_brand: detectedBrand,
          location: safeLocation,
          latitude: latitude != null ? Number(latitude) : 0,
          longitude: longitude != null ? Number(longitude) : 0,
          is_open: true,
        })
        .select('station_id')
        .single();

      if (stationErr || !newStation) {
        console.error('Failed to create gas station:', stationErr);
        return fail(res, 500, 'Could not create station for registration');
      }

      assignedStationId = newStation.station_id;
    }

    const password_hash = await bcrypt.hash(password, 10);
    const { data: staff, error } = await supabase
      .from('staff')
      .insert({
        first_name,
        last_name,
        email: email.toLowerCase().trim(),
        password_hash,
        station_id: assignedStationId,
        role: role || 'attendant',
        contact_number
      })
      .select(STAFF_FIELDS)
      .single();

    if (error) {
      if (error.code === '23505') return fail(res, 409, 'Email already registered');
      return fail(res, 500, 'Could not create staff account');
    }
    return ok(res, 201, { staff, token: signToken(staff.staff_id) }, 'Account created');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) return fail(res, 400, 'email and password required');
    const { data: row } = await supabase
      .from('staff')
      .select(`${STAFF_FIELDS}, password_hash`)
      .eq('email', email.toLowerCase().trim())
      .maybeSingle();
    const valid = row && row.password_hash && (await bcrypt.compare(password, row.password_hash));
    if (!valid) return fail(res, 401, 'Invalid email or password');
    const { password_hash, ...staff } = row;
    return ok(res, 200, { staff, token: signToken(staff.staff_id) }, 'Login successful');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function me(req, res) {
  const { data: staff } = await supabase.from('staff').select(STAFF_FIELDS).eq('staff_id', req.staffId).maybeSingle();
  if (!staff) return fail(res, 404, 'Not found');
  return ok(res, 200, { staff }, 'OK');
}

module.exports = { register, login, me };

async function updateMe(req, res) {
  const { first_name, last_name, contact_number } = req.body || {};
  const updates = {};
  if (first_name !== undefined) updates.first_name = first_name;
  if (last_name !== undefined) updates.last_name = last_name;
  if (contact_number !== undefined) updates.contact_number = contact_number;
  const { data: staff, error } = await supabase.from('staff').update(updates).eq('staff_id', req.staffId).select(STAFF_FIELDS).single();
  if (error) return fail(res, 500, 'Could not update');
  return ok(res, 200, { staff }, 'Updated');
}
module.exports = { register, login, me, updateMe };