import { useEffect, useState } from 'react';
import api from '../api/client';
import { useAuth } from '../context/AuthContext';

const COLORS = ['#E8450A', '#F5A623', '#2E7D32', '#003DA5', '#8a3a1f'];

function BarChart({ data }) {
  const entries = Object.entries(data);
  const max = Math.max(...entries.map(([, v]) => v), 1);
  return (
    <svg width="100%" height="160" viewBox={`0 0 ${entries.length * 60} 160`}>
      {entries.map(([day, val], i) => {
        const h = (val / max) * 120;
        return (
          <g key={day}>
            <rect x={i * 60 + 10} y={140 - h} width="30" height={h} rx="4" fill="#E8450A" />
            <text x={i * 60 + 25} y="155" fontSize="9" textAnchor="middle" fill="#888">{day.slice(5)}</text>
          </g>
        );
      })}
    </svg>
  );
}

function PieChart({ data }) {
  const entries = Object.entries(data);
  const total = entries.reduce((s, [, v]) => s + v, 0) || 1;

  if (entries.length === 1) {
    return (
      <div style={{ display: 'flex', gap: 20, alignItems: 'center' }}>
        <svg width="160" height="160" viewBox="0 0 160 160">
          <circle cx="80" cy="80" r="70" fill={COLORS[0]} />
        </svg>
        <div style={{ fontSize: 12 }}>
          <span style={{ width: 10, height: 10, background: COLORS[0], borderRadius: 2, display: 'inline-block', marginRight: 6 }} />
          {entries[0][0]}: {entries[0][1].toFixed(1)} L (100%)
        </div>
      </div>
    );
  }

  let angle = 0;
  const radius = 70, cx = 80, cy = 80;
  const slices = entries.map(([label, val], i) => {
    const frac = val / total;
    const start = angle;
    angle += frac * 360;
    const end = angle;
    const large = end - start > 180 ? 1 : 0;
    const x1 = cx + radius * Math.cos((Math.PI * start) / 180 - Math.PI / 2);
    const y1 = cy + radius * Math.sin((Math.PI * start) / 180 - Math.PI / 2);
    const x2 = cx + radius * Math.cos((Math.PI * end) / 180 - Math.PI / 2);
    const y2 = cy + radius * Math.sin((Math.PI * end) / 180 - Math.PI / 2);
    return { path: `M${cx},${cy} L${x1},${y1} A${radius},${radius} 0 ${large} 1 ${x2},${y2} Z`, color: COLORS[i % COLORS.length], label, val };
  });

  return (
    <div style={{ display: 'flex', gap: 20, alignItems: 'center' }}>
      <svg width="160" height="160" viewBox="0 0 160 160">
        {slices.map((s) => <path key={s.label} d={s.path} fill={s.color} />)}
      </svg>
      <div>
        {slices.map((s) => (
          <div key={s.label} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4, fontSize: 12 }}>
            <span style={{ width: 10, height: 10, background: s.color, borderRadius: 2, display: 'inline-block' }} />
            {s.label}: {s.val.toFixed(1)} L
          </div>
        ))}
      </div>
    </div>
  );
}

function Card({ label, value }) {
  return (
    <div style={{ background: '#fff', borderRadius: 12, padding: 20, flex: 1, boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
      <p style={{ margin: 0, fontSize: 12, color: '#999', textTransform: 'uppercase' }}>{label}</p>
      <p style={{ margin: '6px 0 0', fontSize: 24, fontWeight: 700 }}>{value}</p>
    </div>
  );
}

export default function Dashboard() {
  const { staff } = useAuth();
  const [sales, setSales] = useState(null);
  const [ai, setAi] = useState(null);
  const [orders, setOrders] = useState([]);
  const [promos, setPromos] = useState([]);

  useEffect(() => {
    api.get('/staff/reports/sales').then((r) => setSales(r.data.data));
    api.get('/staff/reports/ai-analytics').then((r) => setAi(r.data.data));
    api.get('/staff/orders').then((r) => setOrders(r.data.data.orders));
    api.get('/staff/promotions').then((r) => setPromos(r.data.data.promotions));
  }, []);

  const pending = orders.filter((o) => o.status === 'pending').length;

  return (
    <div>
      <h2>Dashboard</h2>
      <p>Welcome back, {staff?.first_name}!</p>

      <div style={{ display: 'flex', gap: 16, marginTop: 20 }}>
        <Card label="Total Revenue" value={sales ? `₱${sales.total_revenue.toFixed(0)}` : '—'} />
        <Card label="Orders Fulfilled" value={sales ? sales.total_orders : '—'} />
        <Card label="Pending Orders" value={pending} />
        <Card label="Active Promotions" value={promos.filter((p) => p.is_active).length} />
      </div>

      <div style={{ display: 'flex', gap: 20, marginTop: 24 }}>
        <div style={{ background: '#fff', borderRadius: 12, padding: 20, flex: 1.3, boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
          <h3 style={{ marginTop: 0 }}>Revenue by Day</h3>
          {sales && Object.keys(sales.by_day).length > 0
            ? <BarChart data={sales.by_day} />
            : <p style={{ color: '#999' }}>No completed sales yet</p>}
        </div>
        <div style={{ background: '#fff', borderRadius: 12, padding: 20, flex: 1, boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
          <h3 style={{ marginTop: 0 }}>Fuel Demand</h3>
          {ai && Object.keys(ai.demand_by_fuel_type).length > 0
            ? <PieChart data={ai.demand_by_fuel_type} />
            : <p style={{ color: '#999' }}>No data yet</p>}
        </div>
      </div>
    </div>
  );
}