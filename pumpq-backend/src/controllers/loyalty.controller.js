const supabase = require('../config/supabase');

const ok = (res, status, data, message) =>
  res.status(status).json({ success: true, data, message });
const fail = (res, status, message) =>
  res.status(status).json({ success: false, data: null, message });

async function getLoyalty(req, res) {
  try {
    const { data: account, error } = await supabase
      .from('loyalty_account')
      .select('loyalty_id, points_balance, tier, streak_count')
      .eq('user_id', req.userId)
      .maybeSingle();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Server error');
    }

    // No account yet just means the user hasn't completed an order — that's normal, not an error.
    const account_data = account || {
      points_balance: 0,
      tier: 'Bronze',
      streak_count: 0,
    };

    return ok(res, 200, { loyalty: account_data }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function getLoyaltyHistory(req, res) {
  try {
    const { data: account } = await supabase
      .from('loyalty_account')
      .select('loyalty_id')
      .eq('user_id', req.userId)
      .maybeSingle();

    if (!account) return ok(res, 200, { transactions: [] }, 'OK');

    const { data: transactions, error } = await supabase
      .from('loyalty_transaction')
      .select('lt_id, order_id, points_earned, points_redeemed, created_at')
      .eq('loyalty_id', account.loyalty_id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error(error);
      return fail(res, 500, 'Server error');
    }

    return ok(res, 200, { transactions }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function redeemPoints(req, res) {
  try {
    const { points } = req.body || {};
    if (!points || points < 100 || points % 100 !== 0) {
      return fail(res, 400, 'Points must be redeemed in multiples of 100');
    }

    const { data: account, error } = await supabase
      .from('loyalty_account')
      .select('loyalty_id, points_balance')
      .eq('user_id', req.userId)
      .maybeSingle();

    if (error) {
      console.error(error);
      return fail(res, 500, 'Server error');
    }
    if (!account || account.points_balance < points) {
      return fail(res, 400, 'Not enough points to redeem');
    }

    const newBalance = account.points_balance - points;
    const discountPhp = (points / 100) * 10;

    const { error: updateError } = await supabase
      .from('loyalty_account')
      .update({ points_balance: newBalance })
      .eq('loyalty_id', account.loyalty_id);

    if (updateError) {
      console.error(updateError);
      return fail(res, 500, 'Could not redeem points');
    }

    await supabase.from('loyalty_transaction').insert({
      loyalty_id: account.loyalty_id,
      order_id: null,
      points_earned: 0,
      points_redeemed: points,
    });

    return ok(
      res,
      200,
      { points_balance: newBalance, discount_php: discountPhp },
      'Points redeemed',
    );
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

module.exports = { getLoyalty, getLoyaltyHistory, redeemPoints };