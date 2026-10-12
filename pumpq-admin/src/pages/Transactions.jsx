import { useEffect, useState } from 'react';
import api from '../api/client';

export default function Transactions() {
  const [orders, setOrders] = useState([]);

  async function load() {
    const res = await api.get('/staff/orders');
    setOrders(res.data.data.orders);
  }
  useEffect(() => { load(); }, []);

  async function accept(id) {
    try {
      await api.put(`/staff/orders/${id}/accept`);
      load();
    } catch (e) { alert(e.response?.data?.message || 'Failed'); }
  }

  async function cancel(id) {
    if (!confirm('Cancel this order?')) return;
    try {
      await api.put(`/staff/orders/${id}/cancel`);
      load();
    } catch (e) { alert(e.response?.data?.message || 'Failed'); }
  }

  return (
    <div>
      <h2>Transactions</h2>
      <table border="1" cellPadding="8" style={{ borderCollapse: 'collapse', width: '100%' }}>
        <thead>
          <tr><th>Order #</th><th>Fuel</th><th>Liters</th><th>Amount</th><th>Status</th><th>Payment</th><th>Actions</th></tr>
        </thead>
        <tbody>
          {orders.map((o) => (
            <tr key={o.order_id}>
              <td>{o.order_id}</td>
              <td>{o.fuel_type}</td>
              <td>{o.liters}</td>
              <td>₱{o.amount}</td>
              <td>{o.status}</td>
              <td>{o.payment_status}</td>
              <td>
                {o.status === 'pending' && (
                  <>
                    <button onClick={() => accept(o.order_id)}>Accept</button>{' '}
                    <button onClick={() => cancel(o.order_id)}>Cancel</button>
                  </>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}