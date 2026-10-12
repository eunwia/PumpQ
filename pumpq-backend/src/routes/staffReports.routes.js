const router = require('express').Router();
const { salesReport, aiAnalytics } = require('../controllers/staffReports.controller');
const { requireStaffAuth } = require('../middleware/staffAuth');

router.use(requireStaffAuth);
router.get('/sales', salesReport);
router.get('/ai-analytics', aiAnalytics);

module.exports = router;