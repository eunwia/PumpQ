import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { login, error, loading } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    const ok = await login(email, password);
    if (ok) navigate('/dashboard');
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex' }}>
      <div style={{
        flex: 1, background: 'linear-gradient(145deg,#1A1A1A,#2A1A12)', color: '#fff',
        display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '0 60px',
      }}>
        <h1 style={{ fontSize: 40, margin: 0, lineHeight: 1.2 }}>Pump<span style={{ color: '#E8450A' }}>Q</span></h1>
        <p style={{ color: '#aaa', fontSize: 15, marginTop: 12, maxWidth: 360 }}>
          The staff portal for managing fuel inventory, promotions, transactions, and station analytics.
        </p>
      </div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#fff' }}>
        <form onSubmit={handleSubmit} style={{ width: 340 }}>
          <h2>Welcome back</h2>
          <p style={{ marginBottom: 28 }}>Sign in to your staff account</p>
          <label style={{ fontSize: 12, fontWeight: 600, color: '#444' }}>Email</label>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} style={{ width: '100%', marginTop: 6, marginBottom: 16 }} />
          <label style={{ fontSize: 12, fontWeight: 600, color: '#444' }}>Password</label>
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} style={{ width: '100%', marginTop: 6, marginBottom: 8 }} />
          {error && <p style={{ color: '#D8232A', fontSize: 13, marginBottom: 8 }}>{error}</p>}
          <button type="submit" disabled={loading} style={{ width: '100%', marginTop: 16, padding: 13 }}>
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
          <p style={{ textAlign: 'center', marginTop: 20, fontSize: 13 }}>
            No account? <Link to="/register">Register</Link>
          </p>
        </form>
      </div>
    </div>
  );
}