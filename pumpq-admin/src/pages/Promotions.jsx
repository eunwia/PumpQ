import { useEffect, useState } from 'react';
import api from '../api/client';

export default function Promotions() {
  const [promos, setPromos] = useState([]);
  const [form, setForm] = useState({ promo_name: '', promo_type: 'flat', discount_value: '', promo_tag: '', coupon_code: '', expires_at: '' });

  async function load() {
    const res = await api.get('/staff/promotions');
    setPromos(res.data.data.promotions);
  }
  useEffect(() => { load(); }, []);

  async function handleAdd(e) {
    e.preventDefault();
    await api.post('/staff/promotions', { ...form, discount_value: Number(form.discount_value) });
    setForm({ promo_name: '', promo_type: 'flat', discount_value: '', promo_tag: '', coupon_code: '', expires_at: '' });
    load();
  }

  async function toggleActive(p) {
    await api.put(`/staff/promotions/${p.promo_id}`, { is_active: !p.is_active });
    load();
  }

  async function handleDelete(id) {
    if (!confirm('Delete this promotion?')) return;
    await api.delete(`/staff/promotions/${id}`);
    load();
  }

  return (
    <div>
      <h2>Promotions</h2>
      <form onSubmit={handleAdd} style={{ marginBottom: 20, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <input placeholder="Promo name" value={form.promo_name} onChange={(e) => setForm({ ...form, promo_name: e.target.value })} style={{ padding: 6 }} />
        <select value={form.promo_type} onChange={(e) => setForm({ ...form, promo_type: e.target.value })} style={{ padding: 6 }}>
          <option value="flat">Flat ₱</option>
          <option value="percentage">Percentage %</option>
        </select>
        <input placeholder="Discount value" type="number" value={form.discount_value} onChange={(e) => setForm({ ...form, discount_value: e.target.value })} style={{ padding: 6, width: 100 }} />
        <input placeholder="Tag (e.g. New User)" value={form.promo_tag} onChange={(e) => setForm({ ...form, promo_tag: e.target.value })} style={{ padding: 6 }} />
        <input placeholder="Coupon code" value={form.coupon_code} onChange={(e) => setForm({ ...form, coupon_code: e.target.value })} style={{ padding: 6 }} />
        <input type="date" value={form.expires_at} onChange={(e) => setForm({ ...form, expires_at: e.target.value })} style={{ padding: 6 }} />
        <button type="submit">Add</button>
      </form>
      <table border="1" cellPadding="8" style={{ borderCollapse: 'collapse', width: '100%' }}>
        <thead>
          <tr><th>Name</th><th>Type</th><th>Value</th><th>Code</th><th>Active</th><th>Actions</th></tr>
        </thead>
        <tbody>
          {promos.map((p) => (
            <tr key={p.promo_id}>
              <td>{p.promo_name}</td>
              <td>{p.promo_type}</td>
              <td>{p.discount_value}</td>
              <td>{p.coupon_code}</td>
              <td>{p.is_active ? 'Yes' : 'No'}</td>
              <td>
                <button onClick={() => toggleActive(p)}>Toggle Active</button>{' '}
                <button onClick={() => handleDelete(p.promo_id)}>Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}