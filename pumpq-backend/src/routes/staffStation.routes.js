const router = require('express').Router();
const { listAllStations, compareAllPrices } = require('../controllers/staffStation.controller');
const { requireStaffAuth } = require('../middleware/staffAuth');

router.use(requireStaffAuth);
router.get('/', listAllStations);
router.get('/compare', compareAllPrices);

module.exports = router;