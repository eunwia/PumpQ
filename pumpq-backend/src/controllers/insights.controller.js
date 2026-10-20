const supabase = require('../config/supabase');
const admin = require('../config/firebaseAdmin');

const ok = (res, status, data, message) =>
  res.status(status).json({ success: true, data, message });
const fail = (res, status, message) =>
  res.status(status).json({ success: false, data: null, message });

async function sendRefuelReminderNotification(userId, daysUntil) {
  try {
    const { data: user } = await supabase.from('user').select('fcm_token').eq('user_id', userId).maybeSingle();
    if (user?.fcm_token) {
      const body = daysUntil <= 0
        ? "You're due for a refuel today based on your usual driving habits!"
        : `Refuel reminder: You're expected to need a refuel in ${daysUntil} day(s).`;
      await admin.messaging().send({
        token: user.fcm_token,
        notification: {
          title: '⛽ Refuel Reminder',
          body,
        },
      });
    }
  } catch (err) {
    console.error('Refuel reminder push error:', err.message);
  }
}

async function getBudget(req, res) {
  try {
    const { data: user, error: userError } = await supabase
      .from('user')
      .select('monthly_budget')
      .eq('user_id', req.userId)
      .single();

    if (userError) {
      console.error(userError);
      return fail(res, 500, 'Server error');
    }

    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const { data: orders, error: ordersError } = await supabase
      .from('order')
      .select('amount')
      .eq('user_id', req.userId)
      .eq('status', 'completed')
      .gte('created_at', startOfMonth.toISOString());

    if (ordersError) {
      console.error(ordersError);
      return fail(res, 500, 'Server error');
    }

    const spent = orders.reduce((sum, o) => sum + Number(o.amount), 0);
    const budget = Number(user.monthly_budget) || 0;
    const percentUsed = budget > 0 ? Math.round((spent / budget) * 100) : 0;

    let alertLevel = 'none';
    if (percentUsed >= 100) alertLevel = 'exceeded';
    else if (percentUsed >= 80) alertLevel = 'warning';

    return ok(
      res,
      200,
      { budget, spent: Number(spent.toFixed(2)), percent_used: percentUsed, alert_level: alertLevel },
      'OK',
    );
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function updateBudget(req, res) {
  try {
    const { budget } = req.body || {};
    if (typeof budget !== 'number' || budget < 0) {
      return fail(res, 400, 'budget must be a non-negative number');
    }

    const { error } = await supabase
      .from('user')
      .update({ monthly_budget: budget })
      .eq('user_id', req.userId);

    if (error) {
      console.error(error);
      return fail(res, 500, 'Could not update budget');
    }

    return ok(res, 200, { budget }, 'Budget updated');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

// Moving-average refuel prediction based on the user's own completed order history.
async function getReminder(req, res) {
  try {
    const { data: orders, error } = await supabase
      .from('order')
      .select('created_at')
      .eq('user_id', req.userId)
      .eq('status', 'completed')
      .order('created_at', { ascending: true });

    if (error) {
      console.error(error);
      return fail(res, 500, 'Server error');
    }

    if (orders.length < 2) {
      return ok(
        res,
        200,
        { has_enough_data: false, average_interval_days: null, predicted_next_refuel: null },
        'Not enough order history yet',
      );
    }

    const dates = orders.map((o) => new Date(o.created_at));
    const intervals = [];
    for (let i = 1; i < dates.length; i++) {
      const diffDays = (dates[i] - dates[i - 1]) / (1000 * 60 * 60 * 24);
      intervals.push(diffDays);
    }

    const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;
    const lastRefuel = dates[dates.length - 1];
    const predictedNext = new Date(lastRefuel.getTime() + avgInterval * 24 * 60 * 60 * 1000);
    const daysUntil = Math.ceil((predictedNext - new Date()) / (1000 * 60 * 60 * 24));

    if (daysUntil <= 1) {
      sendRefuelReminderNotification(req.userId, daysUntil).catch(() => {});
    }

    return ok(
      res,
      200,
      {
        has_enough_data: true,
        average_interval_days: Math.round(avgInterval * 10) / 10,
        predicted_next_refuel: predictedNext.toISOString(),
        days_until_next_refuel: daysUntil,
      },
      'OK',
    );
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

module.exports = { getBudget, updateBudget, getReminder };