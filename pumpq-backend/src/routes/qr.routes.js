const router = require('express').Router();
const { generateQr, validateQr } = require('../controllers/qr.controller');
const { requireAuth } = require('../middleware/auth');

router.post('/generate', requireAuth, generateQr);
router.post('/validate', validateQr); // staff-side; no user JWT — the QR itself is the credential

module.exports = router;