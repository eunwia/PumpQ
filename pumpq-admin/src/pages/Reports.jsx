import { useEffect, useMemo, useState } from 'react';
import api from '../api/client';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

const ORANGE = '#E8450A';
const COLORS = ['#E8450A', '#1A1A1A', '#B8340A', '#F5765C', '#6B7280'];
const cardBox = { height: 440, display: 'flex', flexDirection: 'column', minWidth: 0 };
const scrollBox = { flex: 1, minHeight: 0, overflowY: 'auto' };

function ymd(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function Bar({ pct, color }) {
  return (
    <div style={{ background: '#f2f2f2', borderRadius: 6, height: 6 }}>
      <div style={{ width: `${pct}%`, background: color, height: 6, borderRadius: 6 }} />
    </div>
  );
}

function OrderRow({ o }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '9px 0', borderBottom: '1px solid #F2F2F2', fontSize: 12 }}>
      <span><strong>#{o.order_id}</strong> <span style={{ color: '#888' }}>· {o.fuel_type} · {o.liters} L</span></span>
      <span style={{ fontWeight: 600 }}>₱{Number(o.amount).toFixed(2)}</span>
    </div>
  );
}

export default function Reports() {
  const [sales, setSales] = useState(null);
  const [ai, setAi] = useState(null);
  const [pickedDay, setPickedDay] = useState('');

  useEffect(() => {
    api.get('/staff/reports/sales').then((r) => setSales(r.data.data));
    api.get('/staff/reports/ai-analytics').then((r) => setAi(r.data.data));
  }, []);

  const todayKey = ymd(new Date());

  // Days that have sales, newest first
  const salesDays = useMemo(
    () => (sales ? Object.keys(sales.by_day).sort().reverse() : []),
    [sales]
  );

  // Selected day defaults to the most recent day with sales, else today
  const selectedDay = pickedDay || salesDays[0] || todayKey;

  function dayStats(key) {
    const orders = sales ? sales.orders.filter((o) => o.created_at.slice(0, 10) === key) : [];
    const revenue = orders.reduce((s, o) => s + Number(o.amount || 0), 0);
    const liters = orders.reduce((s, o) => s + Number(o.liters || 0), 0);
    const byFuel = {};
    orders.forEach((o) => { byFuel[o.fuel_type] = (byFuel[o.fuel_type] || 0) + Number(o.amount || 0); });
    return { orders, revenue, liters, fuels: Object.entries(byFuel).sort((a, b) => b[1] - a[1]) };
  }

  const today = useMemo(() => dayStats(todayKey), [sales, todayKey]);
  const picked = useMemo(() => dayStats(selectedDay), [sales, selectedDay]);

  // Previous calendar week (Mon-Sun), zero-filled
  const lastWeek = useMemo(() => {
    if (!sales) return { days: [], total: 0, max: 1 };
    const now = new Date();
    const dow = (now.getDay() + 6) % 7; // Mon = 0
    const days = Array.from({ length: 7 }, (_, i) => {
      const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dow - 7 + i);
      const key = ymd(d);
      return {
        key,
        label: d.toLocaleDateString('en-US', { weekday: 'short' }),
        amt: Number(sales.by_day[key] || 0),
      };
    });
    return { days, total: days.reduce((s, d) => s + d.amt, 0), max: Math.max(...days.map((d) => d.amt), 1) };
  }, [sales]);

  // Revenue per fuel type (all time, used in the PDF)
  const breakdown = useMemo(() => {
    if (!sales) return [];
    const map = {};
    sales.orders.forEach((o) => { map[o.fuel_type] = (map[o.fuel_type] || 0) + Number(o.amount || 0); });
    return Object.entries(map).sort((a, b) => b[1] - a[1]);
  }, [sales]);

  function exportPdf() {
    if (!sales) return;
    const doc = new jsPDF();
    const head = { fillColor: [232, 69, 10] };

    doc.setFontSize(18);
    doc.text('PumpQ Sales Report', 14, 18);
    doc.setFontSize(10);
    doc.setTextColor(120);
    doc.text(`Generated ${new Date().toLocaleDateString()}`, 14, 25);

    autoTable(doc, {
      startY: 32,
      head: [['Metric', 'Value']],
      body: [
        ['Total Revenue', `PHP ${sales.total_revenue.toFixed(2)}`],
        ['Revenue Today', `PHP ${today.revenue.toFixed(2)}`],
        ['Total Orders', String(sales.total_orders)],
        ['Liters Sold', `${sales.total_liters.toFixed(1)} L`],
      ],
      headStyles: head,
    });

    autoTable(doc, {
      startY: doc.lastAutoTable.finalY + 10,
      head: [['Date', 'Revenue']],
      body: Object.entries(sales.by_day).map(([day, amt]) => [day, `PHP ${amt.toFixed(2)}`]),
      headStyles: head,
    });

    autoTable(doc, {
      startY: doc.lastAutoTable.finalY + 10,
      head: [['Order #', 'Fuel', 'Liters', 'Amount', 'Date']],
      body: sales.orders.map((o) => [
        `#${o.order_id}`, o.fuel_type, o.liters, `PHP ${Number(o.amount).toFixed(2)}`, o.created_at.slice(0, 10),
      ]),
      headStyles: head,
    });

    autoTable(doc, {
      startY: doc.lastAutoTable.finalY + 10,
      head: [['Last Week', 'Revenue']],
      body: [
        ...lastWeek.days.map((d) => [`${d.label} ${d.key}`, `PHP ${d.amt.toFixed(2)}`]),
        ['Total', `PHP ${lastWeek.total.toFixed(2)}`],
      ],
      headStyles: head,
    });

    autoTable(doc, {
      startY: doc.lastAutoTable.finalY + 10,
      head: [['Fuel Type', 'Revenue', 'Share']],
      body: breakdown.map(([type, amt]) => [
        type, `PHP ${amt.toFixed(2)}`,
        `${sales.total_revenue > 0 ? ((amt / sales.total_revenue) * 100).toFixed(0) : 0}%`,
      ]),
      headStyles: head,
    });

    if (ai) {
      autoTable(doc, {
        startY: doc.lastAutoTable.finalY + 10,
        head: [[`AI Demand (top seller: ${ai.top_fuel_type || 'N/A'})`, 'Liters Sold']],
        body: Object.entries(ai.demand_by_fuel_type).map(([type, l]) => [type, `${l.toFixed(1)} L`]),
        headStyles: head,
      });
    }

    doc.save('pumpq_sales_report.pdf');
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2>Reports & Analytics</h2>
        <button onClick={exportPdf}>Export PDF</button>
      </div>

      {sales && (
        <div style={{ display: 'flex', gap: 16, marginTop: 20 }}>
          <div className="card" style={{ flex: 1 }}>
            <p style={{ fontSize: 11, textTransform: 'uppercase', color: '#999' }}>Total Revenue</p>
            <p style={{ fontSize: 26, fontWeight: 700, margin: '8px 0 0' }}>₱{sales.total_revenue.toFixed(2)}</p>
          </div>
          <div className="card" style={{ flex: 1 }}>
            <p style={{ fontSize: 11, textTransform: 'uppercase', color: '#999' }}>Total Orders</p>
            <p style={{ fontSize: 26, fontWeight: 700, margin: '8px 0 0' }}>{sales.total_orders}</p>
          </div>
          <div className="card" style={{ flex: 1 }}>
            <p style={{ fontSize: 11, textTransform: 'uppercase', color: '#999' }}>Liters Sold</p>
            <p style={{ fontSize: 26, fontWeight: 700, margin: '8px 0 0' }}>{sales.total_liters.toFixed(1)} L</p>
          </div>
        </div>
      )}

      <div style={{ display: 'flex', gap: 20, marginTop: 20, alignItems: 'stretch' }}>
        {/* Revenue Today */}
        <div className="card" style={{ flex: 1, ...cardBox }}>
          <h3>Revenue Today</h3>
          <div style={{ fontSize: 26, fontWeight: 700, color: ORANGE }}>₱{today.revenue.toFixed(2)}</div>
          <p style={{ fontSize: 12, margin: '2px 0 14px' }}>
            {todayKey} · {today.orders.length} {today.orders.length === 1 ? 'order' : 'orders'} · {today.liters.toFixed(1)} L
          </p>
          <div style={{ ...scrollBox, paddingRight: 4 }}>
            {today.orders.length === 0 && <p style={{ fontSize: 13 }}>No sales yet today.</p>}
            {today.orders.map((o) => <OrderRow key={o.order_id} o={o} />)}
          </div>
        </div>

        {/* Revenue Last Week */}
        <div className="card" style={{ flex: 1, ...cardBox }}>
          <h3>Revenue Last Week</h3>
          <div style={{ fontSize: 26, fontWeight: 700, color: ORANGE }}>₱{lastWeek.total.toFixed(2)}</div>
          <p style={{ fontSize: 12, margin: '2px 0 14px' }}>
            {lastWeek.days.length > 0 && `${lastWeek.days[0].key} to ${lastWeek.days[6].key}`}
          </p>
          <div style={{ ...scrollBox, paddingRight: 4 }}>
            {lastWeek.days.map((d) => (
              <div key={d.key} style={{ marginBottom: 10 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                  <span>{d.label} <span style={{ color: '#aaa' }}>{d.key.slice(5)}</span></span>
                  <span style={{ fontWeight: 600 }}>₱{d.amt.toFixed(2)}</span>
                </div>
                <Bar pct={(d.amt / lastWeek.max) * 100} color={ORANGE} />
              </div>
            ))}
          </div>
        </div>

        {/* Total Revenue Breakdown (pick a day) */}
        <div className="card" style={{ flex: 1, ...cardBox }}>
          <h3 style={{ marginBottom: 10 }}>Total Revenue Breakdown</h3>

          <input
            type="date"
            value={selectedDay}
            onChange={(e) => setPickedDay(e.target.value)}
            style={{ width: '100%', padding: '9px 12px', fontSize: 13 }}
          />

          {salesDays.length > 0 && (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 10 }}>
              {salesDays.slice(0, 4).map((d) => {
                const active = d === selectedDay;
                return (
                  <button key={d} onClick={() => setPickedDay(d)} style={{
                    background: active ? '#FDEBE4' : '#fff', color: active ? ORANGE : '#555',
                    border: `1px solid ${active ? ORANGE : '#E5E5E5'}`, borderRadius: 999,
                    padding: '4px 10px', fontSize: 11, fontWeight: 600, boxShadow: 'none', width: 'auto',
                  }}>{d.slice(5)}</button>
                );
              })}
            </div>
          )}

          <div style={{ fontSize: 26, fontWeight: 700, color: ORANGE, marginTop: 14 }}>₱{picked.revenue.toFixed(2)}</div>
          <p style={{ fontSize: 12, margin: '2px 0 12px' }}>
            {selectedDay} · {picked.orders.length} {picked.orders.length === 1 ? 'order' : 'orders'} · {picked.liters.toFixed(1)} L
          </p>

          <div style={{ ...scrollBox, paddingRight: 4 }}>
            {picked.orders.length === 0 && <p style={{ fontSize: 13 }}>No sales on this day.</p>}
            {picked.fuels.map(([type, amt], i) => {
              const pct = picked.revenue > 0 ? (amt / picked.revenue) * 100 : 0;
              return (
                <div key={type} style={{ marginBottom: 12 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                    <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span style={{ width: 8, height: 8, borderRadius: '50%', background: COLORS[i % COLORS.length] }} />
                      {type}
                    </span>
                    <span style={{ fontWeight: 600 }}>₱{amt.toFixed(2)} · {pct.toFixed(0)}%</span>
                  </div>
                  <Bar pct={pct} color={COLORS[i % COLORS.length]} />
                </div>
              );
            })}
            {picked.orders.length > 0 && (
              <div style={{ marginTop: 14 }}>
                {picked.orders.map((o) => <OrderRow key={o.order_id} o={o} />)}
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="card" style={{ marginTop: 20 }}>
        <h3>AI Demand Analytics</h3>
        {ai && <p style={{ marginBottom: 14 }}>Top seller: <strong style={{ color: '#E8450A' }}>{ai.top_fuel_type || 'N/A'}</strong> · based on {ai.sample_size} completed orders</p>}
        <table style={{ boxShadow: 'none' }}>
          <thead><tr><th>Fuel Type</th><th>Liters Sold</th></tr></thead>
          <tbody>
            {ai && Object.entries(ai.demand_by_fuel_type).map(([type, l]) => (
              <tr key={type}><td>{type}</td><td>{l.toFixed(1)} L</td></tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}