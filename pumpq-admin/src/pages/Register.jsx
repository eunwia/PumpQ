import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../api/client';

const labelStyle = { fontSize: 12, fontWeight: 600, color: '#444' };
const inputStyle = { width: '100%', marginTop: 6, marginBottom: 16 };

function Field({ label, children }) {
  return (
    <div style={{ flex: 1, minWidth: 0 }}>
      <label style={labelStyle}>{label}</label>
      {children}
    </div>
  );
}

export default function Register() {
  const [form, setForm] = useState({ first_name: '', last_name: '', email: '', password: '', station_id: '', contact_number: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  function set(k) { return (e) => setForm({ ...form, [k]: e.target.value }); }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await api.post('/staff/auth/register', { ...form, station_id: Number(form.station_id) });
      navigate('/login');
    } catch (err) {
      setError(err.response?.data?.message || 'Registration failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex' }}>
      <div style={{
        flex: 1, background: 'linear-gradient(145deg,#1A1A1A,#2A1A12)', color: '#fff',
        display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '0 60px',
      }}>
        <h1 style={{ fontSize: 40, margin: 0, lineHeight: 1.2 }}>Pump<span style={{ color: '#E8450A' }}>Q</span></h1>
        <p style={{ color: '#aaa', fontSize: 15, marginTop: 12, maxWidth: 360 }}>
          Create your staff account to start managing fuel inventory, promotions, transactions, and station analytics.
        </p>
      </div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#fff', padding: '40px 0' }}>
        <form onSubmit={handleSubmit} style={{ width: 340 }}>
          <h2>Create an account</h2>
          <p style={{ marginBottom: 28 }}>Register your staff account</p>

          <div style={{ display: 'flex', gap: 12 }}>
            <Field label="First name">
              <input value={form.first_name} onChange={set('first_name')} style={inputStyle} />
            </Field>
            <Field label="Last name">
              <input value={form.last_name} onChange={set('last_name')} style={inputStyle} />
            </Field>
          </div>

          <label style={labelStyle}>Email</label>
          <input type="email" value={form.email} onChange={set('email')} style={inputStyle} />

          <label style={labelStyle}>Password</label>
          <input type="password" value={form.password} onChange={set('password')} style={inputStyle} />

          <div style={{ display: 'flex', gap: 12 }}>
            <Field label="Station ID">
              <input type="number" value={form.station_id} onChange={set('station_id')} style={inputStyle} />
            </Field>
            <Field label="Contact number">
              <input value={form.contact_number} onChange={set('contact_number')} style={inputStyle} />
            </Field>
          </div>

          {error && <p style={{ color: '#D8232A', fontSize: 13, marginBottom: 8 }}>{error}</p>}
          <button type="submit" disabled={loading} style={{ width: '100%', marginTop: 8, padding: 13 }}>
            {loading ? 'Creating account...' : 'Register'}
          </button>
          <p style={{ textAlign: 'center', marginTop: 20, fontSize: 13 }}>
            Already have an account? <Link to="/login">Sign in</Link>
          </p>
        </form>
      </div>
    </div>
  );
}