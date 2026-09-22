const router = require('express').Router();
const { getLoyalty, getLoyaltyHistory, redeemPoints } = require('../controllers/loyalty.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/', getLoyalty);
router.get('/history', getLoyaltyHistory);
router.post('/redeem', redeemPoints);

module.exports = router;