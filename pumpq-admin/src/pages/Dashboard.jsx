import { useEffect, useState } from 'react';
import api from '../api/client';
import { useAuth } from '../context/AuthContext';

const COLORS = ['#E8450A', '#1A1A1A', '#B8340A', '#F5765C', '#6B7280'];const CARD = { background: '#fff', borderRadius: 18, padding: 22, boxShadow: '0 2px 10px rgba(0,0,0,0.05)' };
const GRADIENTS = [
  'linear-gradient(135deg,#F5765C,#E8450A)',
  'linear-gradient(135deg,#B8340A,#1A1A1A)',
  'linear-gradient(135deg,#1A1A1A,#3A3A3A)',
  'linear-gradient(135deg,#E8450A,#8a3a1f)',
];
const STATUS_COLOR = { pending: '#E8450A', completed: '#1A1A1A', cancelled: '#B8340A' };

function SmoothLine({ data }) {
  const entries = Object.entries(data);
  if (entries.length === 0) return <p style={{ color: '#aaa' }}>No data yet</p>;
  const max = Math.max(...entries.map(([, v]) => v), 1);
  const w = 480, h = 140, pad = 20;
  const step = entries.length > 1 ? (w - pad * 2) / (entries.length - 1) : 0;
  const pts = entries.map(([, v], i) => [pad + i * step, h - pad - (v / max) * (h - pad * 2)]);
  const path = pts.reduce((acc, [x, y], i) => {
    if (i === 0) return `M${x},${y}`;
    const [px, py] = pts[i - 1];
    const cx = (px + x) / 2;
    return acc + ` C${cx},${py} ${cx},${y} ${x},${y}`;
  }, '');
  const areaPath = `${path} L${pts[pts.length - 1][0]},${h - pad} L${pts[0][0]},${h - pad} Z`;
  return (
    <svg width="100%" height={h} viewBox={`0 0 ${w} ${h}`}>
      <defs><linearGradient id="grad" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#E8450A" stopOpacity="0.25" /><stop offset="100%" stopColor="#E8450A" stopOpacity="0" /></linearGradient></defs>
      <path d={areaPath} fill="url(#grad)" />
      <path d={path} fill="none" stroke="#E8450A" strokeWidth="2.5" strokeLinecap="round" />
      {pts.map(([x, y], i) => <circle key={i} cx={x} cy={y} r="4" fill="#fff" stroke="#E8450A" strokeWidth="2" />)}
      {entries.map(([day], i) => <text key={day} x={pts[i][0]} y={h - 2} fontSize="9" textAnchor="middle" fill="#999">{day.slice(5)}</text>)}
    </svg>
  );
}

function Donut({ percent, color, label }) {
  const r = 55, circ = 2 * Math.PI * r;
  return (
    <div style={{ position: 'relative', width: 140, height: 140, margin: '0 auto' }}>
      <svg width="140" height="140" viewBox="0 0 140 140">
        <circle cx="70" cy="70" r={r} fill="none" stroke="#f3f3f3" strokeWidth="14" />
        <circle cx="70" cy="70" r={r} fill="none" stroke={color} strokeWidth="14" strokeLinecap="round"
          strokeDasharray={circ} strokeDashoffset={circ - (percent / 100) * circ} transform="rotate(-90 70 70)" />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <span style={{ fontSize: 24, fontWeight: 700 }}>{percent}%</span>
        <span style={{ fontSize: 10, color: '#999' }}>{label}</span>
      </div>
    </div>
  );
}

function ProgressRow({ label, value, max, color }) {
  const pct = max > 0 ? (value / max) * 100 : 0;
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 6 }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ width: 8, height: 8, borderRadius: '50%', background: color, display: 'inline-block' }} />{label}</span>
        <span style={{ fontWeight: 600 }}>{value.toFixed(1)} L</span>
      </div>
      <div style={{ background: '#f2f2f2', borderRadius: 6, height: 8 }}><div style={{ width: `${pct}%`, background: color, height: 8, borderRadius: 6 }} /></div>
    </div>
  );
}

function GradientCard({ label, value, gradient }) {
  return (
    <div style={{ background: gradient, borderRadius: 18, padding: 20, flex: 1, color: '#fff', boxShadow: '0 4px 14px rgba(0,0,0,0.12)' }}>
      <p style={{ margin: 0, fontSize: 11, opacity: 0.85, textTransform: 'uppercase' }}>{label}</p>
      <p style={{ margin: '8px 0 0', fontSize: 24, fontWeight: 700 }}>{value}</p>
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
  const completed = orders.filter((o) => o.status === 'completed').length;
  const completionRate = orders.length > 0 ? Math.round((completed / orders.length) * 100) : 0;
  const demand = ai ? Object.entries(ai.demand_by_fuel_type) : [];
  const maxDemand = Math.max(...demand.map(([, v]) => v), 1);
  const recent = [...orders].sort((a, b) => new Date(b.created_at) - new Date(a.created_at)).slice(0, 6);

  const stats = [
    { label: 'Total Revenue', value: sales ? `₱${sales.total_revenue.toFixed(0)}` : '—' },
    { label: 'Orders Fulfilled', value: sales ? sales.total_orders : '—' },
    { label: 'Pending Orders', value: pending },
    { label: 'Active Promotions', value: promos.filter((p) => p.is_active).length },
  ];

  return (
    <div>
      <h2>Dashboard</h2>
      <p>Welcome back, {staff?.first_name}!</p>

      <div style={{ display: 'flex', gap: 16, marginTop: 20 }}>
        {stats.map((s, i) => <GradientCard key={s.label} {...s} gradient={GRADIENTS[i]} />)}
      </div>

      <div style={{ display: 'flex', gap: 20, marginTop: 20 }}>
        <div style={{ ...CARD, flex: 1.6 }}>
          <h3 style={{ marginTop: 0 }}>Revenue Trend</h3>
          {sales && Object.keys(sales.by_day).length > 0 ? <SmoothLine data={sales.by_day} /> : <p style={{ color: '#999' }}>No completed sales yet</p>}
        </div>
        <div style={{ ...CARD, flex: 1, textAlign: 'center' }}>
          <h3 style={{ marginTop: 0, textAlign: 'left' }}>Order Completion</h3>
          <Donut percent={completionRate} color="#E8450A" label={`${completed} of ${orders.length}`} />
        </div>
      </div>

      <div style={{ display: 'flex', gap: 20, marginTop: 20 }}>
        <div style={{ ...CARD, flex: 1 }}>
          <h3 style={{ marginTop: 0 }}>Fuel Demand</h3>
          {demand.length > 0
            ? demand.map(([type, val], i) => <ProgressRow key={type} label={type} value={val} max={maxDemand} color={COLORS[i % COLORS.length]} />)
            : <p style={{ color: '#999' }}>No data yet</p>}
        </div>
        <div style={{ ...CARD, flex: 1.6 }}>
          <h3 style={{ marginTop: 0 }}>Recent Orders</h3>
          <table style={{ boxShadow: 'none' }}>
            <thead><tr><th>Order #</th><th>Fuel</th><th>Amount</th><th>Status</th></tr></thead>
            <tbody>
              {recent.map((o) => (
                <tr key={o.order_id}>
                  <td>#{o.order_id}</td>
                  <td>{o.fuel_type}</td>
                  <td>₱{o.amount}</td>
                  <td><span style={{ background: STATUS_COLOR[o.status] + '22', color: STATUS_COLOR[o.status], padding: '3px 10px', borderRadius: 12, fontSize: 11, fontWeight: 600 }}>{o.status}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}