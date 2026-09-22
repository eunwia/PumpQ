const router = require('express').Router();
const { getWallet, topUp, getHistory } = require('../controllers/wallet.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/', getWallet);
router.post('/topup', topUp);
router.get('/history', getHistory);

module.exports = router;