const router = require('express').Router();
const { register, login, me } = require('../controllers/staffAuth.controller');
const { requireStaffAuth } = require('../middleware/staffAuth');

router.post('/register', register);
router.post('/login', login);
router.get('/me', requireStaffAuth, me);

module.exports = router;