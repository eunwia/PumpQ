const router = require('express').Router();
const { listOrders, acceptOrder, cancelOrder } = require('../controllers/staffOrder.controller');
const { requireStaffAuth } = require('../middleware/staffAuth');

router.use(requireStaffAuth);
router.get('/', listOrders);
router.put('/:id/accept', acceptOrder);
router.put('/:id/cancel', cancelOrder);

module.exports = router;