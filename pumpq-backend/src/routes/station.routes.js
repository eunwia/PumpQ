const router = require('express').Router();
const { listStations, listFuelPrices } = require('../controllers/station.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/', listStations);
router.get('/fuel', listFuelPrices);

module.exports = router;