import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../api/client';

export default function Register() {
  const [form, setForm] = useState({ first_name: '', last_name: '', email: '', password: '', station_id: '', contact_number: '' });
  const [error, setError] = useState('');
  const navigate = useNavigate();

  function set(k) { return (e) => setForm({ ...form, [k]: e.target.value }); }

  async function handleSubmit(e) {
    e.preventDefault();
    try {
      await api.post('/staff/auth/register', { ...form, station_id: Number(form.station_id) });
      navigate('/login');
    } catch (err) {
      setError(err.response?.data?.message || 'Registration failed');
    }
  }

  return (
    <div style={{ maxWidth: 360, margin: '60px auto', fontFamily: 'sans-serif' }}>
      <h2>Register Staff Account</h2>
      <form onSubmit={handleSubmit}>
        <input placeholder="First name" value={form.first_name} onChange={set('first_name')} style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        <input placeholder="Last name" value={form.last_name} onChange={set('last_name')} style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        <input placeholder="Email" type="email" value={form.email} onChange={set('email')} style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        <input placeholder="Password" type="password" value={form.password} onChange={set('password')} style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        <input placeholder="Station ID" type="number" value={form.station_id} onChange={set('station_id')} style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        <input placeholder="Contact number" value={form.contact_number} onChange={set('contact_number')} style={{ width: '100%', padding: 8, marginBottom: 8 }} />
        {error && <p style={{ color: 'red' }}>{error}</p>}
        <button type="submit">Register</button>
      </form>
      <p><Link to="/login">Back to login</Link></p>
    </div>
  );
}