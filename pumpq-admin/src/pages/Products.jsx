import { useEffect, useMemo, useState } from 'react';
import api from '../api/client';
import { useDialog } from '../context/DialogContext';

const ORANGE = '#E8450A';

const S = {
  card: { background: '#fff', borderRadius: 16, boxShadow: '0 2px 10px rgba(0,0,0,0.04)', border: '1px solid #F0F0F0' },
  primaryBtn: {
    background: `linear-gradient(135deg,#F5765C,${ORANGE})`, color: '#fff', border: 'none',
    borderRadius: 10, padding: '10px 18px', fontSize: 13, fontWeight: 600, cursor: 'pointer',
    boxShadow: '0 4px 12px rgba(232,69,10,0.25)', width: 'auto',
  },
  ghostBtn: {
    background: '#fff', color: '#444', border: '1px solid #E5E5E5', borderRadius: 8,
    padding: '6px 12px', fontSize: 12, fontWeight: 500, cursor: 'pointer', boxShadow: 'none', width: 'auto',
  },
  input: {
    border: '1px solid #E5E5E5', borderRadius: 10, padding: '10px 14px', fontSize: 13,
    background: '#fff', outline: 'none', width: 'auto', margin: 0,
  },
  th: { textAlign: 'left', padding: '12px 16px', fontSize: 12, fontWeight: 600, color: '#888', background: '#FAFAFA', borderBottom: '1px solid #F0F0F0' },
  td: { padding: '14px 16px', fontSize: 13, borderBottom: '1px solid #F5F5F5' },
};

function StatCard({ label, value, tint, color }) {
  return (
    <div style={{ ...S.card, padding: 18, display: 'flex', alignItems: 'center', gap: 14, flex: 1 }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12, background: tint, color,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, fontSize: 18,
      }}>●</div>
      <div>
        <div style={{ fontSize: 12, color: '#888' }}>{label}</div>
        <div style={{ fontSize: 22, fontWeight: 700, color: '#111' }}>{value}</div>
      </div>
    </div>
  );
}

function SortIcon({ dir }) {
  return (
    <svg width="10" height="14" viewBox="0 0 10 14" style={{ marginLeft: 6, flexShrink: 0 }}>
      <path d="M5 1 L9 5 H1 Z" fill={dir === 'asc' ? ORANGE : '#CCC'} />
      <path d="M5 13 L1 9 H9 Z" fill={dir === 'desc' ? ORANGE : '#CCC'} />
    </svg>
  );
}

function SortTh({ label, field, sort, onSort }) {
  return (
    <th style={{ ...S.th, cursor: 'pointer', userSelect: 'none' }} onClick={() => onSort(field)}>
      <span style={{ display: 'inline-flex', alignItems: 'center' }}>
        {label}<SortIcon dir={sort.key === field ? sort.dir : null} />
      </span>
    </th>
  );
}

export default function Products() {
  const { confirm: confirmDialog, prompt: promptDialog } = useDialog();
  const [postings, setPostings] = useState([]);
  const [form, setForm] = useState({ fuel_type: '', price: '' });
  const [showForm, setShowForm] = useState(false);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState({ key: null, dir: null });
  const [hoverId, setHoverId] = useState(null);

  function toggleSort(key) {
    setSort((s) => {
      if (s.key !== key) return { key, dir: 'asc' };
      if (s.dir === 'asc') return { key, dir: 'desc' };
      return { key: null, dir: null };
    });
  }

  async function load() { const r = await api.get('/staff/fuel'); setPostings(r.data.data.postings); }
  useEffect(() => { load(); }, []);

  async function handleAdd(e) {
    e.preventDefault();
    if (!form.fuel_type || !form.price) return;
    if (!await confirmDialog(`Add "${form.fuel_type}" at ₱${form.price} per liter?`)) return;
    await api.post('/staff/fuel', { fuel_type: form.fuel_type, price: Number(form.price), availability: true });
    setForm({ fuel_type: '', price: '' });
    setShowForm(false);
    load();
  }

  async function toggleAvailability(p) {
    const nextLabel = p.availability ? 'unavailable' : 'available';
    if (!await confirmDialog(`Do you wish to make "${p.fuel_type}" ${nextLabel}?`)) return;
    await api.put(`/staff/fuel/${p.price_id}`, { availability: !p.availability });
    load();
  }

  async function updatePrice(p) {
    const np = await promptDialog({ title: 'Edit Price', message: 'New price:', defaultValue: p.price, inputType: 'number' });
    if (np == null || np === '') return;
    if (!await confirmDialog(`Update "${p.fuel_type}" price from ₱${p.price} to ₱${np}?`)) return;
    await api.put(`/staff/fuel/${p.price_id}`, { price: Number(np) });
    load();
  }

  async function handleDelete(p) {
    if (!await confirmDialog({ message: `Delete "${p.fuel_type}" from your station's offerings? This cannot be undone.`, isDestructive: true })) return;
    await api.delete(`/staff/fuel/${p.price_id}`);
    load();
  }

  const stats = useMemo(() => {
    const available = postings.filter((p) => p.availability).length;
    const avg = postings.length ? postings.reduce((s, p) => s + Number(p.price), 0) / postings.length : 0;
    return { total: postings.length, available, unavailable: postings.length - available, avg };
  }, [postings]);

  const rows = useMemo(() => {
    const r = postings.filter((p) =>
      (filter === 'all' || (filter === 'available' ? p.availability : !p.availability)) &&
      p.fuel_type.toLowerCase().includes(search.toLowerCase())
    );
    if (!sort.key) return r;
    const dir = sort.dir === 'asc' ? 1 : -1;
    return [...r].sort((a, b) =>
      sort.key === 'fuel_type'
        ? dir * String(a.fuel_type).localeCompare(String(b.fuel_type))
        : dir * (Number(a.price) - Number(b.price))
    );
  }, [postings, filter, search, sort]);

  const tabs = [
    { key: 'all', label: `All Products (${stats.total})` },
    { key: 'available', label: `Available (${stats.available})` },
    { key: 'unavailable', label: `Unavailable (${stats.unavailable})` },
  ];

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <div>
          <h2 style={{ margin: 0, fontSize: 26 }}>Products</h2>
        </div>
        <button onClick={() => setShowForm((v) => !v)} style={S.primaryBtn}>
          {showForm ? '✕ Close' : '+ Add Fuel Type'}
        </button>
      </div>

      {/* Stat cards */}
      <div style={{ display: 'flex', gap: 16, marginBottom: 24 }}>
        <StatCard label="Total Products" value={stats.total} tint="#FDEBE4" color={ORANGE} />
        <StatCard label="Available" value={stats.available} tint="#E6F6EC" color="#1E8E4E" />
        <StatCard label="Unavailable" value={stats.unavailable} tint="#FDE8E4" color="#B8340A" />
        <StatCard label="Avg. Price / L" value={`₱${stats.avg.toFixed(2)}`} tint="#F0F0F0" color="#111" />
      </div>

      {/* Add form (collapsible) */}
      {showForm && (
        <form onSubmit={handleAdd} style={{ ...S.card, padding: 18, marginBottom: 24, display: 'flex', gap: 10, alignItems: 'center' }}>
          <input style={{ ...S.input, flex: 1 }} placeholder="e.g. Diesel" value={form.fuel_type}
            onChange={(e) => setForm({ ...form, fuel_type: e.target.value })} />
          <input style={{ ...S.input, width: 160 }} placeholder="Price per liter" type="number" value={form.price}
            onChange={(e) => setForm({ ...form, price: e.target.value })} />
          <button type="submit" style={S.primaryBtn}>Add</button>
        </form>
      )}

      {/* Filter tabs + toolbar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div style={{ display: 'flex', gap: 8 }}>
          {tabs.map((t) => {
            const active = filter === t.key;
            return (
              <button key={t.key} onClick={() => setFilter(t.key)} style={{
                background: active ? '#FDEBE4' : '#fff', color: active ? ORANGE : '#555',
                border: `1px solid ${active ? ORANGE : '#E5E5E5'}`, borderRadius: 999,
                padding: '7px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', boxShadow: 'none', width: 'auto',
              }}>{t.label}</button>
            );
          })}
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <input style={{ ...S.input, width: 200 }} placeholder="Search fuel type..." value={search}
            onChange={(e) => setSearch(e.target.value)} />
          <button style={{ ...S.ghostBtn, padding: '8px 14px' }}
            onClick={() => toggleSort('price')}>
            Sort by price {sort.key === 'price' ? (sort.dir === 'asc' ? '↑' : '↓') : '↕'}
          </button>
        </div>
      </div>

      {/* Table */}
      <div style={{ ...S.card, overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', boxShadow: 'none' }}>
          <thead>
            <tr>
              <SortTh label="Fuel Type" field="fuel_type" sort={sort} onSort={toggleSort} />
              <SortTh label="Price / L" field="price" sort={sort} onSort={toggleSort} />
              <th style={S.th}>Status</th>
              <th style={{ ...S.th, textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p) => (
              <tr key={p.price_id}
                onMouseEnter={() => setHoverId(p.price_id)} onMouseLeave={() => setHoverId(null)}
                style={{ background: hoverId === p.price_id ? '#FFF6F2' : 'transparent', transition: 'background .15s' }}>
                <td style={{ ...S.td, fontWeight: 600, color: '#111' }}>{p.fuel_type}</td>
                <td style={S.td}>₱{p.price}</td>
                <td style={S.td}>
                  <span style={{
                    padding: '4px 12px', borderRadius: 999, fontSize: 11, fontWeight: 600,
                    background: p.availability ? '#E6F6EC' : '#FDE8E4',
                    color: p.availability ? '#1E8E4E' : '#B8340A',
                  }}>{p.availability ? 'Available' : 'Unavailable'}</span>
                </td>
                <td style={{ ...S.td, textAlign: 'right' }}>
                  <div style={{ display: 'inline-flex', gap: 8 }}>
                    <button style={S.ghostBtn} onClick={() => updatePrice(p)}>Edit Price</button>
                    <button style={S.ghostBtn} onClick={() => toggleAvailability(p)}>
                      {p.availability ? 'Make Unavailable' : 'Make Available'}
                    </button>
                    <button onClick={() => handleDelete(p)} style={{ ...S.ghostBtn, color: '#B8340A', borderColor: '#F5C9BD' }}>Delete</button>
                  </div>
                </td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr><td colSpan={4} style={{ ...S.td, textAlign: 'center', color: '#999', padding: 40 }}>No products found.</td></tr>
            )}
          </tbody>
        </table>
        <div style={{ padding: '12px 16px', fontSize: 12, color: '#888' }}>
          Showing {rows.length} of {stats.total}
        </div>
      </div>
    </div>
  );
}