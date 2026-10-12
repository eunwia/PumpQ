const router = require('express').Router();
const { list, create, update, remove } = require('../controllers/staffPromotion.controller');
const { requireStaffAuth } = require('../middleware/staffAuth');

router.use(requireStaffAuth);
router.get('/', list);
router.post('/', create);
router.put('/:id', update);
router.delete('/:id', remove);

module.exports = router;