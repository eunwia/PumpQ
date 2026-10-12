const router = require('express').Router();
const { broadcast } = require('../controllers/staffNotification.controller');
const { requireStaffAuth } = require('../middleware/staffAuth');

router.post('/broadcast', requireStaffAuth, broadcast);

module.exports = router;