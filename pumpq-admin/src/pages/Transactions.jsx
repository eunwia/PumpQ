import { useEffect, useMemo, useState } from 'react';
import api from '../api/client';

const ORANGE = '#E8450A';

const GROUPS = [
  { key: 'pending', label: 'Pending', color: '#F5A623' },
  { key: 'completed', label: 'Completed', color: '#2E7D32' },
  { key: 'cancelled', label: 'Cancelled', color: '#D8232A' },
];

const S = {
  card: { background: '#fff', borderRadius: 16, boxShadow: '0 2px 10px rgba(0,0,0,0.04)', border: '1px solid #F0F0F0' },
  th: { textAlign: 'left', padding: '10px 10px', whiteSpace: 'nowrap', fontSize: 12, fontWeight: 500, color: '#999', borderBottom: '1px solid #EEE', background: 'transparent' },
  td: { padding: '14px 10px', whiteSpace: 'nowrap', fontSize: 13, borderBottom: '1px solid #EEE', color: '#222' },
  input: { border: '1px solid #E5E5E5', borderRadius: 10, padding: '8px 14px', fontSize: 13, background: '#fff', outline: 'none', width: 200, margin: 0 },
  accept: {
    background: `linear-gradient(135deg,#F5765C,${ORANGE})`, color: '#fff', border: 'none', borderRadius: 8,
    padding: '6px 14px', fontSize: 12, fontWeight: 600, cursor: 'pointer', boxShadow: 'none', width: 'auto',
  },
  ghost: {
    background: '#fff', color: '#444', border: '1px solid #E5E5E5', borderRadius: 8,
    padding: '6px 14px', fontSize: 12, fontWeight: 500, cursor: 'pointer', boxShadow: 'none', width: 'auto',
  },
};

function StatusPill({ status }) {
  const g = GROUPS.find((x) => x.key === status);
  const color = g ? g.color : '#888';
  return (
    <span style={{ background: color + '1A', color, fontSize: 11, fontWeight: 600, padding: '4px 12px', borderRadius: 999, textTransform: 'capitalize' }}>
      {status}
    </span>
  );
}

function SideCard({ title, children }) {
  return (
    <div style={{ ...S.card, padding: 18 }}>
      <div style={{ fontSize: 12, color: '#888', marginBottom: 8 }}>{title}</div>
      {children}
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

export default function Transactions() {
  const [orders, setOrders] = useState([]);
  const [tab, setTab] = useState('all');
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState({ key: null, dir: null });

  function toggleSort(key) {
    setSort((s) => {
      if (s.key !== key) return { key, dir: 'asc' };
      if (s.dir === 'asc') return { key, dir: 'desc' };
      return { key: null, dir: null };
    });
  }

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

  const counts = useMemo(() => {
    const c = { all: orders.length };
    GROUPS.forEach((g) => { c[g.key] = orders.filter((o) => o.status === g.key).length; });
    return c;
  }, [orders]);

  const revenue = useMemo(
    () => orders.filter((o) => o.status === 'completed').reduce((s, o) => s + Number(o.amount || 0), 0),
    [orders]
  );
  const pct = counts.all ? Math.round((counts.completed / counts.all) * 100) : 0;

  const rows = useMemo(() => {
    const q = search.trim().toLowerCase();
    const filtered = orders.filter((o) =>
      (tab === 'all' || o.status === tab) &&
      (!q || String(o.order_id).includes(q) || String(o.fuel_type).toLowerCase().includes(q))
    );
    if (!sort.key) return filtered;
    const dir = sort.dir === 'asc' ? 1 : -1;
    return [...filtered].sort((a, b) => {
      if (sort.key === 'fuel_type') return dir * String(a.fuel_type).localeCompare(String(b.fuel_type));
      return dir * (Number(a[sort.key]) - Number(b[sort.key]));
    });
  }, [orders, tab, search, sort]);

  const tabs = [{ key: 'all', label: 'All' }, ...GROUPS];

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 24 }}>
        <div>
          <h2 style={{ margin: 0, fontSize: 26 }}>Transactions</h2>
        </div>
        <input style={S.input} placeholder="Search order # or fuel..." value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>

      <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
        {/* Main table */}
        <div style={{ ...S.card, flex: 1, padding: 20, minWidth: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <h3 style={{ margin: 0, fontSize: 16 }}>Orders</h3>
            <div style={{ display: 'flex', background: '#F4F4F4', borderRadius: 999, padding: 3 }}>
              {tabs.map((t) => {
                const active = tab === t.key;
                return (
                  <button key={t.key} onClick={() => setTab(t.key)} style={{
                    background: active ? ORANGE : 'transparent', color: active ? '#fff' : '#666',
                    border: 'none', borderRadius: 999, padding: '6px 14px', fontSize: 12, fontWeight: 600,
                    cursor: 'pointer', boxShadow: 'none', width: 'auto',
                  }}>
                    {t.label} <span style={{ opacity: 0.75 }}>{counts[t.key]}</span>
                  </button>
                );
              })}
            </div>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', boxShadow: 'none', background: 'transparent' }}>
              <thead>
                <tr>
                  <SortTh label="Order #" field="order_id" sort={sort} onSort={toggleSort} />
                  <SortTh label="Fuel" field="fuel_type" sort={sort} onSort={toggleSort} />
                  <SortTh label="Liters" field="liters" sort={sort} onSort={toggleSort} />
                  <SortTh label="Amount" field="amount" sort={sort} onSort={toggleSort} />
                  <th style={S.th}>Payment</th>
                  <th style={S.th}>Status</th>
                  <th style={{ ...S.th, textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((o) => (
                  <tr key={o.order_id}>
                    <td style={{ ...S.td, fontWeight: 600 }}>#{o.order_id}</td>
                    <td style={S.td}>{o.fuel_type}</td>
                    <td style={S.td}>{o.liters}</td>
                    <td style={{ ...S.td, fontWeight: 600 }}>₱{o.amount}</td>
                    <td style={{ ...S.td, textTransform: 'capitalize' }}>{o.payment_status}</td>
                    <td style={S.td}><StatusPill status={o.status} /></td>
                    <td style={{ ...S.td, textAlign: 'right' }}>
                      {o.status === 'pending' ? (
                        <div style={{ display: 'inline-flex', gap: 8 }}>
                          <button style={S.accept} onClick={() => accept(o.order_id)}>Accept</button>
                          <button style={S.ghost} onClick={() => cancel(o.order_id)}>Cancel</button>
                        </div>
                      ) : (
                        <span style={{ color: '#CCC' }}>—</span>
                      )}
                    </td>
                  </tr>
                ))}
                {rows.length === 0 && (
                  <tr><td colSpan={7} style={{ ...S.td, textAlign: 'center', color: '#999', padding: 40, borderBottom: 'none' }}>No orders found.</td></tr>
                )}
              </tbody>
            </table>
          </div>
          <div style={{ paddingTop: 14, fontSize: 12, color: '#888' }}>Showing {rows.length} of {counts.all}</div>
        </div>

        {/* Summary column */}
        <div style={{ width: 250, display: 'flex', flexDirection: 'column', gap: 16, flexShrink: 0 }}>
          <SideCard title="Order completion">
            <div style={{ height: 8, borderRadius: 999, background: '#F0F0F0', overflow: 'hidden' }}>
              <div style={{ width: `${pct}%`, height: '100%', background: `linear-gradient(90deg,#F5765C,${ORANGE})` }} />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 12 }}>
              <span style={{ color: '#888' }}>{counts.completed} of {counts.all} completed</span>
              <span style={{ fontWeight: 600 }}>{pct}%</span>
            </div>
          </SideCard>

          <SideCard title="Completed revenue">
            <div style={{ fontSize: 26, fontWeight: 700, color: ORANGE }}>₱{revenue.toLocaleString()}</div>
          </SideCard>

          <SideCard title="By status">
            {GROUPS.map((g) => (
              <div key={g.key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 0', borderBottom: g.key !== 'cancelled' ? '1px solid #F2F2F2' : 'none' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}>
                  <span style={{ width: 8, height: 8, borderRadius: '50%', background: g.color }} />
                  {g.label}
                </div>
                <span style={{ background: g.color + '1A', color: g.color, fontSize: 11, fontWeight: 600, padding: '2px 10px', borderRadius: 10 }}>{counts[g.key]}</span>
              </div>
            ))}
          </SideCard>
        </div>
      </div>
    </div>
  );
}