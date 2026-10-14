import { useState } from 'react';
import api from '../api/client';
import { useAuth } from '../context/AuthContext';

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

  return (
    <div>
      <h2>My Account</h2>
      <p>Manage your staff profile information</p>

      <div style={{ display: 'flex', gap: 20, marginTop: 20 }}>
        <div className="card" style={{ flex: 1, textAlign: 'center' }}>
          <div style={{ width: 72, height: 72, borderRadius: '50%', background: 'linear-gradient(135deg,#F5765C,#E8450A)', margin: '0 auto 14px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 26, fontWeight: 700 }}>
            {staff?.first_name?.[0]?.toUpperCase()}
          </div>
          <p style={{ color: '#1A1A1A', fontWeight: 600 }}>{staff?.first_name} {staff?.last_name}</p>
          <p style={{ fontSize: 13 }}>{staff?.email}</p>
          <p style={{ fontSize: 12, marginTop: 6 }}>Role: <strong style={{ color: '#E8450A' }}>{staff?.role}</strong></p>
        </div>
        <div className="card" style={{ flex: 1.5 }}>
          <h3>Edit Details</h3>
          <form onSubmit={handleSave}>
            <label style={{ fontSize: 12, fontWeight: 600, color: '#444' }}>First name</label>
            <input value={firstName} onChange={(e) => setFirstName(e.target.value)} style={{ width: '100%', marginTop: 6, marginBottom: 14 }} />
            <label style={{ fontSize: 12, fontWeight: 600, color: '#444' }}>Last name</label>
            <input value={lastName} onChange={(e) => setLastName(e.target.value)} style={{ width: '100%', marginTop: 6, marginBottom: 14 }} />
            <label style={{ fontSize: 12, fontWeight: 600, color: '#444' }}>Contact number</label>
            <input value={contact} onChange={(e) => setContact(e.target.value)} style={{ width: '100%', marginTop: 6, marginBottom: 14 }} />
            <button type="submit">Save Changes</button>
            {msg && <p style={{ marginTop: 10, color: '#2E7D32', fontSize: 13 }}>{msg}</p>}
          </form>
        </div>
      </div>
    </div>
  );
}