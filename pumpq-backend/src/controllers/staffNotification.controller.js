const supabase = require('../config/supabase');
const admin = require('../config/firebaseAdmin');
const ok = (res, status, data, message) => res.status(status).json({ success: true, data, message });
const fail = (res, status, message) => res.status(status).json({ success: false, data: null, message });

async function broadcast(req, res) {
  const { title, body } = req.body || {};
  if (!title || !body) return fail(res, 400, 'title and body required');

  const { data: users, error } = await supabase.from('user').select('fcm_token').not('fcm_token', 'is', null);
  if (error) return fail(res, 500, 'Server error');

  const tokens = users.map((u) => u.fcm_token).filter(Boolean);
  if (tokens.length === 0) return ok(res, 200, { sent: 0 }, 'No registered devices to notify');

  try {
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
    });
    return ok(res, 200, { sent: response.successCount, failed: response.failureCount }, 'Notification sent');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Could not send notifications');
  }
}

module.exports = { broadcast };