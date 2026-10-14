import { useEffect, useState } from 'react';
import api from '../api/client';

const GROUPS = [
  { key: 'pending', label: 'Pending', color: '#F5A623' },
  { key: 'completed', label: 'Completed', color: '#2E7D32' },
  { key: 'cancelled', label: 'Cancelled', color: '#D8232A' },
];

export default function Transactions() {
  const [orders, setOrders] = useState([]);

  async function load() {
    const res = await api.get('/staff/orders');
    setOrders(res.data.data.orders);
  }
  useEffect(() => { load(); }, []);

  async function accept(id) {
    try { await api.put(`/staff/orders/${id}/accept`); load(); }
    catch (e) { alert(e.response?.data?.message || 'Failed'); }
  }
  async function cancel(id) {
    if (!confirm('Cancel this order?')) return;
    try { await api.put(`/staff/orders/${id}/cancel`); load(); }
    catch (e) { alert(e.response?.data?.message || 'Failed'); }
  }

  return (
    <div>
      <h2>Transactions</h2>
      <p>Orders placed at your station, grouped by status</p>

      {GROUPS.map((g) => {
        const rows = orders.filter((o) => o.status === g.key);
        return (
          <div className="card" key={g.key} style={{ marginTop: 20 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
              <span style={{ width: 10, height: 10, borderRadius: '50%', background: g.color, display: 'inline-block' }} />
              <h3 style={{ margin: 0 }}>{g.label}</h3>
              <span style={{ background: g.color + '1A', color: g.color, fontSize: 11, fontWeight: 600, padding: '2px 10px', borderRadius: 10 }}>{rows.length}</span>
            </div>
            {rows.length === 0 ? (
              <p style={{ fontSize: 13 }}>No {g.label.toLowerCase()} orders</p>
            ) : (
              <table style={{ boxShadow: 'none' }}>
                <thead><tr><th>Order #</th><th>Fuel</th><th>Liters</th><th>Amount</th><th>Payment</th>{g.key === 'pending' && <th>Actions</th>}</tr></thead>
                <tbody>
                  {rows.map((o) => (
                    <tr key={o.order_id}>
                      <td>#{o.order_id}</td><td>{o.fuel_type}</td><td>{o.liters}</td><td>₱{o.amount}</td><td>{o.payment_status}</td>
                      {g.key === 'pending' && (
                        <td><button onClick={() => accept(o.order_id)}>Accept</button>{' '}
                          <button onClick={() => cancel(o.order_id)} style={{ background: '#f0f0f0', color: '#444', boxShadow: 'none' }}>Cancel</button></td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        );
      })}
    </div>
  );
}