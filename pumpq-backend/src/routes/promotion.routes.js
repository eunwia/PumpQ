const router = require('express').Router();
const { listPromotions, applyCoupon } = require('../controllers/promotion.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/', listPromotions);
router.post('/apply', applyCoupon);

module.exports = router;