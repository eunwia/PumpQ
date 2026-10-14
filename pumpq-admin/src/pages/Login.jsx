import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
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
          <div style={{ position: 'relative', marginTop: 6, marginBottom: 8 }}>
            <input
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={{ width: '100%', margin: 0, paddingRight: 44 }}
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              aria-label={showPassword ? 'Hide password' : 'Show password'}
              style={{
                position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)',
                background: 'none', border: 'none', boxShadow: 'none', padding: 6, width: 'auto',
                cursor: 'pointer', color: '#888', display: 'flex', alignItems: 'center',
              }}
            >
              {showPassword ? (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24" />
                  <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68" />
                  <path d="M6.61 6.61A13.53 13.53 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61" />
                  <line x1="2" y1="2" x2="22" y2="22" />
                </svg>
              ) : (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
                  <circle cx="12" cy="12" r="3" />
                </svg>
              )}
            </button>
          </div>
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