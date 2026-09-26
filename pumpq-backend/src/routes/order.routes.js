const router = require('express').Router();
const { createOrder, listOrders, getOrder, cancelOrder, payOrder } = require('../controllers/order.controller'); // CHANGED
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth); // every order route requires a logged-in user

router.post('/', createOrder);
router.get('/', listOrders);
router.get('/:id', getOrder);
router.put('/:id/cancel', cancelOrder);
router.put('/:id/pay', payOrder);

module.exports = router;