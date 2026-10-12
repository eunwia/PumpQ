import { useEffect, useState } from 'react';
import api from '../api/client';

export default function Products() {
  const [postings, setPostings] = useState([]);
  const [form, setForm] = useState({ fuel_type: '', price: '' });

  async function load() {
    const res = await api.get('/staff/fuel');
    setPostings(res.data.data.postings);
  }

  useEffect(() => { load(); }, []);

  async function handleAdd(e) {
    e.preventDefault();
    await api.post('/staff/fuel', { fuel_type: form.fuel_type, price: Number(form.price), availability: true });
    setForm({ fuel_type: '', price: '' });
    load();
  }

  async function toggleAvailability(p) {
    await api.put(`/staff/fuel/${p.price_id}`, { availability: !p.availability });
    load();
  }

  async function updatePrice(p) {
    const newPrice = prompt('New price:', p.price);
    if (newPrice == null) return;
    await api.put(`/staff/fuel/${p.price_id}`, { price: Number(newPrice) });
    load();
  }

  async function handleDelete(id) {
    if (!confirm('Delete this fuel posting?')) return;
    await api.delete(`/staff/fuel/${id}`);
    load();
  }

  return (
    <div>
      <h2>Fuel Products</h2>
      <form onSubmit={handleAdd} style={{ marginBottom: 20 }}>
        <input placeholder="Fuel type (e.g. Diesel)" value={form.fuel_type} onChange={(e) => setForm({ ...form, fuel_type: e.target.value })} style={{ marginRight: 8, padding: 6 }} />
        <input placeholder="Price" type="number" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} style={{ marginRight: 8, padding: 6 }} />
        <button type="submit">Add</button>
      </form>
      <table border="1" cellPadding="8" style={{ borderCollapse: 'collapse', width: '100%' }}>
        <thead>
          <tr><th>Fuel Type</th><th>Price</th><th>Available</th><th>Actions</th></tr>
        </thead>
        <tbody>
          {postings.map((p) => (
            <tr key={p.price_id}>
              <td>{p.fuel_type}</td>
              <td>₱{p.price}</td>
              <td>{p.availability ? 'Yes' : 'No'}</td>
              <td>
                <button onClick={() => updatePrice(p)}>Edit Price</button>{' '}
                <button onClick={() => toggleAvailability(p)}>Toggle Availability</button>{' '}
                <button onClick={() => handleDelete(p.price_id)}>Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}