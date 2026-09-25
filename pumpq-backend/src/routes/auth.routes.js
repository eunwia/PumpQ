const router = require('express').Router();
const { register, login, me, logout, updateMe } = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);
router.post('/logout', requireAuth, logout);
router.get('/me', requireAuth, me);
router.put('/me', requireAuth, updateMe);

module.exports = router;