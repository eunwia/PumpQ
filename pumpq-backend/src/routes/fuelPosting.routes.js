const router = require('express').Router();
const { listMine, create, update, remove } = require('../controllers/fuelPosting.controller');
const { requireStaffAuth } = require('../middleware/staffAuth');

router.use(requireStaffAuth);
router.get('/', listMine);
router.post('/', create);
router.put('/:id', update);
router.delete('/:id', remove);

module.exports = router;