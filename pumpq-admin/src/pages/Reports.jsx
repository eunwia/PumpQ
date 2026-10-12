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
    const header = 'Order ID,Amount,Liters,Fuel Type,Date\n';
    const rows = sales.orders.map((o) => `${o.order_id},${o.amount},${o.liters},${o.fuel_type},${o.created_at.slice(0, 10)}`).join('\n');
    const blob = new Blob([header + rows], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'pumpq_sales_report.csv';
    a.click();
  }

  return (
    <div>
      <h2>Reports & Analytics</h2>
      {sales && (
        <>
          <h3>Sales Summary</h3>
          <p>Total Orders: {sales.total_orders}</p>
          <p>Total Revenue: ₱{sales.total_revenue.toFixed(2)}</p>
          <p>Total Liters Sold: {sales.total_liters.toFixed(1)}</p>
          <button onClick={exportCsv}>Export CSV</button>
          <h4>Revenue by Day</h4>
          <table border="1" cellPadding="6"><tbody>
            {Object.entries(sales.by_day).map(([day, amt]) => (
              <tr key={day}><td>{day}</td><td>₱{amt.toFixed(2)}</td></tr>
            ))}
          </tbody></table>
        </>
      )}
      {ai && (
        <>
          <h3 style={{ marginTop: 24 }}>AI Analytics (Demand by Fuel Type)</h3>
          <p>Top seller: {ai.top_fuel_type || 'N/A'} (based on {ai.sample_size} orders)</p>
          <table border="1" cellPadding="6"><tbody>
            {Object.entries(ai.demand_by_fuel_type).map(([type, liters]) => (
              <tr key={type}><td>{type}</td><td>{liters.toFixed(1)} L</td></tr>
            ))}
          </tbody></table>
        </>
      )}
    </div>
  );
}