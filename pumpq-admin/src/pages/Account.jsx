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
      setMsg('Saved!');
    } catch {
      setMsg('Update failed');
    }
  }

  return (
    <div style={{ maxWidth: 400 }}>
      <h2>My Account</h2>
      <p>Email: {staff?.email}</p>
      <p>Role: {staff?.role}</p>
      <form onSubmit={handleSave}>
        <input value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="First name" style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        <input value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="Last name" style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        <input value={contact} onChange={(e) => setContact(e.target.value)} placeholder="Contact number" style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        {msg && <p>{msg}</p>}
        <button type="submit">Save</button>
      </form>
    </div>
  );
}