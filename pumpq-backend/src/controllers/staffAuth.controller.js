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
    const { first_name, last_name, email, password, station_id, role, contact_number } = req.body || {};
    if (!first_name || !last_name || !email || !password || !station_id) {
      return fail(res, 400, 'first_name, last_name, email, password, station_id are required');
    }
    const password_hash = await bcrypt.hash(password, 10);
    const { data: staff, error } = await supabase
      .from('staff')
      .insert({ first_name, last_name, email: email.toLowerCase().trim(), password_hash, station_id, role: role || 'attendant', contact_number })
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