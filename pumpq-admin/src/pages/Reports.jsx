import { useEffect, useState } from 'react';
import api from '../api/client';

export default function Reports() {
  const [sales, setSales] = useState(null);
  const [ai, setAi] = useState(null);

  useEffect(() => {
    api.get('/staff/reports/sales').then((r) => setSales(r.data.data));
    api.get('/staff/reports/ai-analytics').then((r) => setAi(r.data.data));
  }, []);

  function exportCsv() {
    if (!sales) return;
    const rows = sales.orders.map((o) => `${o.order_id},${o.amount},${o.liters},${o.fuel_type},${o.created_at.slice(0, 10)}`).join('\n');
    const blob = new Blob([`Order ID,Amount,Liters,Fuel,Date\n${rows}`], { type: 'text/csv' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'pumpq_sales_report.csv';
    a.click();
  }

  return (
    <div>
      <h2>Reports & Analytics</h2>
      <p>Sales performance and demand insights for your station</p>

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

      <div className="card" style={{ marginTop: 20 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 style={{ margin: 0 }}>Revenue by Day</h3>
          <button onClick={exportCsv}>Export CSV</button>
        </div>
        <table style={{ marginTop: 14, boxShadow: 'none' }}>
          <thead><tr><th>Date</th><th>Revenue</th></tr></thead>
          <tbody>
            {sales && Object.entries(sales.by_day).map(([day, amt]) => (
              <tr key={day}><td>{day}</td><td>₱{amt.toFixed(2)}</td></tr>
            ))}
          </tbody>
        </table>
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