const admin = require('firebase-admin');
const { getMessaging } = require('firebase-admin/messaging');
let serviceAccount;
try {
  serviceAccount = require('../../firebase-service-account.json');
} catch (_) {
  serviceAccount = require('../../firebase-service-account.json.json');
}

const app = admin.initializeApp({
  credential: admin.cert(serviceAccount),
});

// firebase-admin v14+ removed the legacy admin.messaging() shorthand.
// Attach a compatible shim so all existing callers (staffNotification,
// staffOrder, qr controllers) can continue to use admin.messaging().send/sendEachForMulticast.
admin.messaging = () => getMessaging(app);

module.exports = admin;