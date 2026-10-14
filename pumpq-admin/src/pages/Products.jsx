import { useEffect, useState } from 'react';
import api from '../api/client';

export default function Products() {
  const [postings, setPostings] = useState([]);
  const [form, setForm] = useState({ fuel_type: '', price: '' });

  async function load() { const r = await api.get('/staff/fuel'); setPostings(r.data.data.postings); }
  useEffect(() => { load(); }, []);

  async function handleAdd(e) {
    e.preventDefault();
    if (!form.fuel_type || !form.price) return;
    if (!confirm(`Add "${form.fuel_type}" at ₱${form.price} per liter?`)) return;
    await api.post('/staff/fuel', { fuel_type: form.fuel_type, price: Number(form.price), availability: true });
    setForm({ fuel_type: '', price: '' });
    load();
  }

  async function toggleAvailability(p) {
    const nextLabel = p.availability ? 'unavailable' : 'available';
    if (!confirm(`Do you wish to make "${p.fuel_type}" ${nextLabel}?`)) return;
    await api.put(`/staff/fuel/${p.price_id}`, { availability: !p.availability });
    load();
  }

  async function updatePrice(p) {
    const np = prompt('New price:', p.price);
    if (np == null || np === '') return;
    if (!confirm(`Update "${p.fuel_type}" price from ₱${p.price} to ₱${np}?`)) return;
    await api.put(`/staff/fuel/${p.price_id}`, { price: Number(np) });
    load();
  }

  async function handleDelete(p) {
    if (!confirm(`Delete "${p.fuel_type}" from your station's offerings? This cannot be undone.`)) return;
    await api.delete(`/staff/fuel/${p.price_id}`);
    load();
  }

  return (
    <div>
      <h2>Fuel Products</h2>
      <p>Manage the fuel types and prices offered at your station</p>

      <div className="card" style={{ marginTop: 20 }}>
        <h3>Add Fuel Type</h3>
        <form onSubmit={handleAdd} style={{ display: 'flex', gap: 10 }}>
          <input placeholder="e.g. Diesel" value={form.fuel_type} onChange={(e) => setForm({ ...form, fuel_type: e.target.value })} />
          <input placeholder="Price" type="number" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} />
          <button type="submit">Add Fuel Type</button>
        </form>
      </div>

      <div className="card" style={{ marginTop: 20 }}>
        <h3>Current Offerings</h3>
        <table style={{ boxShadow: 'none' }}>
          <thead><tr><th>Fuel Type</th><th>Price</th><th>Available</th><th>Actions</th></tr></thead>
          <tbody>
            {postings.map((p) => (
              <tr key={p.price_id}>
                <td>{p.fuel_type}</td><td>₱{p.price}</td>
                <td><span style={{ color: p.availability ? '#1A1A1A' : '#B8340A', fontWeight: 600 }}>{p.availability ? 'Yes' : 'No'}</span></td>
                <td>
                  <button onClick={() => updatePrice(p)} style={{ background: '#f0f0f0', color: '#444', boxShadow: 'none' }}>Edit Price</button>{' '}
                  <button onClick={() => toggleAvailability(p)} style={{ background: '#f0f0f0', color: '#444', boxShadow: 'none' }}>
                    {p.availability ? 'Make Unavailable' : 'Make Available'}
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