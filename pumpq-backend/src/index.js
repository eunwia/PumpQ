require('dotenv').config();

const required = ['SUPABASE_URL', 'SUPABASE_SECRET_KEY', 'JWT_SECRET'];
for (const key of required) {
  if (!process.env[key]) {
    console.error(`Missing ${key} in .env`);
    process.exit(1);
  }
}

const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth.routes');
const orderRoutes = require('./routes/order.routes');
const stationRoutes = require('./routes/station.routes');
const qrRoutes = require('./routes/qr.routes');
const loyaltyRoutes = require('./routes/loyalty.routes');
const walletRoutes = require('./routes/wallet.routes');
const insightsRoutes = require('./routes/insights.routes');
const promotionRoutes = require('./routes/promotion.routes');
const staffAuthRoutes = require('./routes/staffAuth.routes');
const fuelPostingRoutes = require('./routes/fuelPosting.routes');
const staffStationRoutes = require('./routes/staffStation.routes');
const staffPromotionRoutes = require('./routes/staffPromotion.routes');
const staffOrderRoutes = require('./routes/staffOrder.routes');
const staffNotificationRoutes = require('./routes/staffNotification.routes');
const staffReportsRoutes = require('./routes/staffReports.routes');


const app = express();
app.use(cors());
app.use(express.json());
app.use('/api/orders', orderRoutes);
app.use('/api/stations', stationRoutes);
app.use('/api/qr', qrRoutes);
app.use('/api/loyalty', loyaltyRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/insights', insightsRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/staff/auth', staffAuthRoutes);
app.use('/api/staff/fuel', fuelPostingRoutes);
app.use('/api/staff/stations', staffStationRoutes);
app.use('/api/staff/promotions', staffPromotionRoutes);
app.use('/api/staff/orders', staffOrderRoutes);
app.use('/api/staff/notifications', staffNotificationRoutes);
app.use('/api/staff/reports', staffReportsRoutes);

app.get('/api/health', (req, res) => {
  res.json({ success: true, data: {}, message: 'PumpQ API is running' });
});

app.use('/api/auth', authRoutes);

app.use((req, res) => {
  res.status(404).json({ success: false, data: null, message: 'Route not found' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ success: false, data: null, message: 'Server error' });
});

const PORT = process.env.PORT || 3000;
// 0.0.0.0 lets your phone reach the server over Wi-Fi, not just this PC.
app.listen(PORT, '0.0.0.0', () => {
  console.log(`PumpQ API listening on port ${PORT}`);
});