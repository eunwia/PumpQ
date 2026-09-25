const router = require('express').Router();
const { register, login, me, logout, updateMe, updateFcmToken } = require('../controllers/auth.controller'); 
const { requireAuth } = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);
router.post('/logout', requireAuth, logout);
router.get('/me', requireAuth, me);
router.put('/me', requireAuth, updateMe);
router.put('/fcm-token', requireAuth, updateFcmToken);

module.exports = router;