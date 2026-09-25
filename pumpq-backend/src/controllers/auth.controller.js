const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');

const USER_FIELDS =
  'user_id, first_name, last_name, email, phone_number, created_at';

const ok = (res, status, data, message) =>
  res.status(status).json({ success: true, data, message });

const fail = (res, status, message) =>
  res.status(status).json({ success: false, data: null, message });

function signToken(userId) {
  return jwt.sign({}, process.env.JWT_SECRET, {
    subject: String(userId),
    expiresIn: '7d',
  });
}

async function register(req, res) {
  try {
    const { first_name, last_name, email, password, phone_number } =
      req.body || {};

    if (!first_name || !last_name || !email || !password) {
      return fail(res, 400, 'first_name, last_name, email and password are required');
    }
    if (typeof password !== 'string' || password.length < 8) {
      return fail(res, 400, 'Password must be at least 8 characters');
    }
    if (!/^\S+@\S+\.\S+$/.test(email)) {
      return fail(res, 400, 'Invalid email address');
    }

    const password_hash = await bcrypt.hash(password, 10);

    const { data: user, error } = await supabase
      .from('user')
      .insert({
        first_name: String(first_name).trim(),
        last_name: String(last_name).trim(),
        email: String(email).trim().toLowerCase(),
        phone_number: phone_number || null,
        password_hash,
      })
      .select(USER_FIELDS)
      .single();

    if (error) {
      if (error.code === '23505') {
        return fail(res, 409, 'Email is already registered');
      }
      console.error(error);
      return fail(res, 500, 'Could not create account');
    }

    return ok(res, 201, { user, token: signToken(user.user_id) }, 'Account created');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      return fail(res, 400, 'email and password are required');
    }

    const { data: row, error } = await supabase
      .from('user')
      .select(`${USER_FIELDS}, password_hash`)
      .eq('email', String(email).trim().toLowerCase())
      .maybeSingle();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Server error');
    }

    const valid =
      row &&
      row.password_hash &&
      (await bcrypt.compare(String(password), row.password_hash));

    if (!valid) {
      return fail(res, 401, 'Invalid email or password');
    }

    const { password_hash, ...user } = row;
    return ok(res, 200, { user, token: signToken(user.user_id) }, 'Login successful');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function me(req, res) {
  try {
    const { data: user, error } = await supabase
      .from('user')
      .select(USER_FIELDS)
      .eq('user_id', req.userId)
      .maybeSingle();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Server error');
    }
    if (!user) return fail(res, 404, 'User not found');

    return ok(res, 200, { user }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}
async function updateMe(req, res) {
  try {
    const { first_name, last_name, phone_number } = req.body || {};

    const updates = {};
    if (first_name !== undefined) updates.first_name = String(first_name).trim();
    if (last_name !== undefined) updates.last_name = String(last_name).trim();
    if (phone_number !== undefined) updates.phone_number = phone_number || null;

    if (Object.keys(updates).length === 0) {
      return fail(res, 400, 'Nothing to update');
    }

    const { data: user, error } = await supabase
      .from('user')
      .update(updates)
      .eq('user_id', req.userId)
      .select(USER_FIELDS)
      .single();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Could not update profile');
    }

    return ok(res, 200, { user }, 'Profile updated');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

// JWTs are stateless, so the app logs out by deleting its stored token.
async function logout(req, res) {
  return ok(res, 200, {}, 'Logged out');
}

module.exports = { register, login, me, logout, updateMe };