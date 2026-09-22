const supabase = require('../config/supabase');

const ok = (res, status, data, message) =>
  res.status(status).json({ success: true, data, message });
const fail = (res, status, message) =>
  res.status(status).json({ success: false, data: null, message });

async function getOrCreateWallet(userId) {
  let { data: wallet, error } = await supabase
    .from('wallet')
    .select('wallet_id, balance')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;

  if (!wallet) {
    const { data: created, error: createError } = await supabase
      .from('wallet')
      .insert({ user_id: userId, balance: 0 })
      .select('wallet_id, balance')
      .single();

    if (createError) throw createError;
    wallet = created;
  }

  return wallet;
}

async function getWallet(req, res) {
  try {
    const wallet = await getOrCreateWallet(req.userId);
    return ok(res, 200, { wallet }, 'OK');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function topUp(req, res) {
  try {
    const { amount, method } = req.body || {};

    if (!amount || typeof amount !== 'number' || amount <= 0) {
      return fail(res, 400, 'amount must be a positive number');
    }
    const validMethods = ['gcash', 'maya', 'qrph'];
    if (!method || !validMethods.includes(method)) {
      return fail(res, 400, `method must be one of: ${validMethods.join(', ')}`);
    }

    // SIMULATED PAYMENT — a real integration would call the GCash/Maya/QR Ph
    // API here, wait for a webhook or redirect confirming payment, and only
    // credit the wallet once that's confirmed. For this project, we credit
    // immediately to demonstrate the wallet and ledger logic end to end.
    const wallet = await getOrCreateWallet(req.userId);
    const newBalance = Number((wallet.balance + amount).toFixed(2));

    const { error: updateError } = await supabase
      .from('wallet')
      .update({ balance: newBalance })
      .eq('wallet_id', wallet.wallet_id);

    if (updateError) {
      console.error(updateError);
      return fail(res, 500, 'Could not update wallet balance');
    }

    const { error: txError } = await supabase.from('wallet_transaction').insert({
      wallet_id: wallet.wallet_id,
      amount,
      transaction_type: `topup_${method}`,
      reference_id: `SIM-${Date.now()}`, // stands in for a real gateway's transaction ID
    });

    if (txError) {
      console.error(txError);
      return fail(res, 500, 'Could not log transaction');
    }

    return ok(res, 200, { balance: newBalance }, 'Top-up successful');
  } catch (err) {
    console.error(err);
    return fail(res, 500, 'Server error');
  }
}

async function getHistory(req, res) {
  try {
    const wallet = await getOrCreateWallet(req.userId);

    const { data: transactions, error } = await supabase
      .from('wallet_transaction')
      .select('wt_id, amount, transaction_type, reference_id, created_at')
      .eq('wallet_id', wallet.wallet_id)
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

module.exports = { getWallet, topUp, getHistory };