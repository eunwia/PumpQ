import { useState } from 'react';
import api from '../api/client';
import { useAuth } from '../context/AuthContext';

const labelStyle = { fontSize: 12, fontWeight: 600, color: '#444' };
const inputStyle = { width: '100%', marginTop: 6, marginBottom: 16 };

function InfoRow({ label, children, last }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: last ? 'none' : '1px solid #F2F2F2', fontSize: 13 }}>
      <span style={{ color: '#888' }}>{label}</span>
      <span style={{ fontWeight: 600, color: '#111' }}>{children}</span>
    </div>
  );
}

export default function Account() {
  const { staff, setStaff } = useAuth();
  const [firstName, setFirstName] = useState(staff?.first_name || '');
  const [lastName, setLastName] = useState(staff?.last_name || '');
  const [contact, setContact] = useState(staff?.contact_number || '');
  const [msg, setMsg] = useState('');

  async function handleSave(e) {
    e.preventDefault();
    try {
      const res = await api.put('/staff/auth/me', { first_name: firstName, last_name: lastName, contact_number: contact });
      setStaff(res.data.data.staff);
      setMsg('Saved successfully');
    } catch { setMsg('Update failed'); }
  }

  function handleReset() {
    setFirstName(staff?.first_name || '');
    setLastName(staff?.last_name || '');
    setContact(staff?.contact_number || '');
    setMsg('');
  }

  const failed = msg === 'Update failed';

  return (
    <div>
      <h2>My Account</h2>

      {/* Profile banner */}
      <div className="card" style={{ marginTop: 20, padding: 0, overflow: 'hidden' }}>
        <div style={{ height: 110, background: 'linear-gradient(145deg,#1A1A1A,#2A1A12)', position: 'relative' }}>
          <div style={{ position: 'absolute', right: -40, top: -60, width: 200, height: 200, borderRadius: '50%', background: 'radial-gradient(circle,rgba(232,69,10,0.45),transparent 70%)' }} />
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 18, padding: '0 28px 22px' }}>
          <div style={{
            position: 'relative', zIndex: 1,
            width: 88, height: 88, borderRadius: '50%', marginTop: -44, flexShrink: 0,
            background: 'linear-gradient(135deg,#F5765C,#E8450A)', border: '4px solid #fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', fontSize: 32, fontWeight: 700, boxShadow: '0 4px 12px rgba(0,0,0,0.12)',
          }}>
            {staff?.first_name?.[0]?.toUpperCase()}
          </div>
          <div style={{ flex: 1, paddingTop: 14 }}>
            <div style={{ fontSize: 20, fontWeight: 700, color: '#111' }}>{staff?.first_name} {staff?.last_name}</div>
            <div style={{ fontSize: 13, color: '#777', marginTop: 2 }}>{staff?.email}</div>
          </div>
          <span style={{
            background: '#FDEBE4', color: '#E8450A', fontSize: 12, fontWeight: 600,
            padding: '6px 14px', borderRadius: 999, textTransform: 'capitalize', marginTop: 14,
          }}>
            {staff?.role}
          </span>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 20, marginTop: 20, alignItems: 'flex-start' }}>
        {/* Account info */}
        <div className="card" style={{ flex: 1 }}>
          <h3>Account Info</h3>
          <InfoRow label="Email">{staff?.email}</InfoRow>
          <InfoRow label="Role"><span style={{ textTransform: 'capitalize', color: '#E8450A' }}>{staff?.role}</span></InfoRow>
          <InfoRow label="Contact" last>{staff?.contact_number || '—'}</InfoRow>
        </div>

        {/* Edit form */}
        <div className="card" style={{ flex: 1.6 }}>
          <h3>Edit Details</h3>
          <form onSubmit={handleSave}>
            <div style={{ display: 'flex', gap: 14 }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <label style={labelStyle}>First name</label>
                <input value={firstName} onChange={(e) => setFirstName(e.target.value)} style={inputStyle} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <label style={labelStyle}>Last name</label>
                <input value={lastName} onChange={(e) => setLastName(e.target.value)} style={inputStyle} />
              </div>
            </div>
            <label style={labelStyle}>Contact number</label>
            <input value={contact} onChange={(e) => setContact(e.target.value)} style={inputStyle} />

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 }}>
              <span style={{ fontSize: 13, color: failed ? '#D8232A' : '#2E7D32' }}>{msg}</span>
              <div style={{ display: 'flex', gap: 10 }}>
                <button type="button" onClick={handleReset} style={{
                  background: '#fff', color: '#444', border: '1px solid #E5E5E5', boxShadow: 'none',
                }}>Reset</button>
                <button type="submit">Save Changes</button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}