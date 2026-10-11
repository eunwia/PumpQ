const router = require('express').Router();
const { register, login, me, updateMe } = require('../controllers/staffAuth.controller');
const { requireStaffAuth } = require('../middleware/staffAuth');

router.post('/register', register);
router.post('/login', login);
router.get('/me', requireStaffAuth, me);
router.put('/me', requireStaffAuth, updateMe);

module.exports = router;