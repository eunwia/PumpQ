const router = require('express').Router();
const { getBudget, updateBudget, getReminder } = require('../controllers/insights.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/budget', getBudget);
router.put('/budget', updateBudget);
router.get('/reminder', getReminder);

module.exports = router;