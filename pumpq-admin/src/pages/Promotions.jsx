import { useEffect, useState } from 'react';
import api from '../api/client';

export default function Promotions() {
  const [promos, setPromos] = useState([]);
  const [form, setForm] = useState({ promo_name: '', promo_type: 'flat', discount_value: '', promo_tag: '', coupon_code: '', expires_at: '' });

  async function load() { const r = await api.get('/staff/promotions'); setPromos(r.data.data.promotions); }
  useEffect(() => { load(); }, []);

  async function handleAdd(e) {
    e.preventDefault();
    if (!form.promo_name || !form.coupon_code) return;
    if (!confirm(`Create promotion "${form.promo_name}" with code "${form.coupon_code}"?`)) return;
    await api.post('/staff/promotions', { ...form, discount_value: Number(form.discount_value) });
    setForm({ promo_name: '', promo_type: 'flat', discount_value: '', promo_tag: '', coupon_code: '', expires_at: '' });
    load();
  }

  async function toggleActive(p) {
    const nextLabel = p.is_active ? 'inactive' : 'active';
    if (!confirm(`Do you wish to make "${p.promo_name}" ${nextLabel}?`)) return;
    await api.put(`/staff/promotions/${p.promo_id}`, { is_active: !p.is_active });
    load();
  }

  async function handleDelete(p) {
    if (!confirm(`Delete promotion "${p.promo_name}" (${p.coupon_code})? This cannot be undone.`)) return;
    await api.delete(`/staff/promotions/${p.promo_id}`);
    load();
  }

  return (
    <div>
      <h2>Promotions</h2>

      <div className="card" style={{ marginTop: 20 }}>
        <h3>New Promotion</h3>
        <form onSubmit={handleAdd} style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'end' }}>
          <input placeholder="Promo name" value={form.promo_name} onChange={(e) => setForm({ ...form, promo_name: e.target.value })} />
          <select value={form.promo_type} onChange={(e) => setForm({ ...form, promo_type: e.target.value })}>
            <option value="flat">Flat ₱</option><option value="percentage">Percentage %</option>
          </select>
          <input placeholder="Value" type="number" style={{ width: 90 }} value={form.discount_value} onChange={(e) => setForm({ ...form, discount_value: e.target.value })} />
          <input placeholder="Tag" value={form.promo_tag} onChange={(e) => setForm({ ...form, promo_tag: e.target.value })} />
          <input placeholder="Coupon code" value={form.coupon_code} onChange={(e) => setForm({ ...form, coupon_code: e.target.value })} />
          <input type="date" value={form.expires_at} onChange={(e) => setForm({ ...form, expires_at: e.target.value })} />
          <button type="submit">Add Promotion</button>
        </form>
      </div>

      <div className="card" style={{ marginTop: 20 }}>
        <h3>Active & Past Promotions</h3>
        <table style={{ boxShadow: 'none' }}>
          <thead><tr><th>Name</th><th>Type</th><th>Value</th><th>Code</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            {promos.map((p) => (
              <tr key={p.promo_id}>
                <td>{p.promo_name}</td><td>{p.promo_type}</td><td>{p.discount_value}</td>
                <td><span style={{ background: '#FFF0EA', color: '#E8450A', padding: '3px 10px', borderRadius: 8, fontWeight: 600, fontSize: 12 }}>{p.coupon_code}</span></td>
                <td><span style={{ color: p.is_active ? '#1A1A1A' : '#999', fontWeight: 600 }}>{p.is_active ? 'Active' : 'Inactive'}</span></td>
                <td>
                  <button onClick={() => toggleActive(p)} style={{ background: '#f0f0f0', color: '#444', boxShadow: 'none' }}>
                    {p.is_active ? 'Make Inactive' : 'Make Active'}
                  </button>{' '}
                  <button onClick={() => handleDelete(p)}>Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}