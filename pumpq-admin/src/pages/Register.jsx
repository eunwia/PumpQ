import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../api/client';
import mascot from '../../images/piq-register.png';

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
  const [showPassword, setShowPassword] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [ripple, setRipple] = useState(null);
  const navigate = useNavigate();

  function set(k) { return (e) => setForm({ ...form, [k]: e.target.value }); }

  function addRipple(e) {
    const r = e.currentTarget.getBoundingClientRect();
    setRipple({ x: e.clientX - r.left, y: e.clientY - r.top, key: Date.now() });
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await api.post('/staff/auth/register', { ...form, station_id: Number(form.station_id) });
      setLeaving(true);
      setTimeout(() => navigate('/login'), 450);
    } catch (err) {
      setError(err.response?.data?.message || 'Registration failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{
      minHeight: '100vh', display: 'flex',
      opacity: leaving ? 0 : 1, transform: leaving ? 'scale(0.98)' : 'none',
      transition: 'opacity .45s ease, transform .45s ease',
    }}>
      <style>{`
        @keyframes pq-ripple { from { transform: scale(0); opacity: .5; } to { transform: scale(1); opacity: 0; } }
        @keyframes pq-spin { to { transform: rotate(360deg); } }
        @keyframes pq-in { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: none; } }
        @keyframes pq-rise { from { opacity: 0; transform: translateY(48px); } to { opacity: 1; transform: none; } }
        @keyframes pq-glow { from { opacity: 0; } to { opacity: 1; } }
      `}</style>

      <div style={{
        flex: 1, position: 'relative', overflow: 'hidden', background: '#000', color: '#fff',
        display: 'flex', flexDirection: 'column', padding: '9vh 60px 0',
      }}>
        {/* Orange glow behind the mascot */}
        <div style={{
          position: 'absolute', left: '50%', bottom: '-25%', transform: 'translateX(-50%)',
          width: '130%', height: '75%', pointerEvents: 'none', animation: 'pq-glow 1s ease both',
          background: 'radial-gradient(circle, rgba(232,69,10,0.38), transparent 65%)',
        }} />

        {/* Text */}
        <div style={{ position: 'relative', zIndex: 1, animation: 'pq-in .6s ease both' }}>
          <h1 style={{ fontSize: 40, margin: 0, lineHeight: 1.2 }}>Pump<span style={{ color: '#E8450A' }}>Q</span></h1>
          <p style={{ color: '#aaa', fontSize: 15, marginTop: 12, maxWidth: 380 }}>
            Create your staff account to start managing fuel inventory, promotions, transactions, and station analytics.
          </p>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 20 }}>
            {['Fuel inventory', 'Promotions', 'Transactions', 'Analytics'].map((t) => (
              <span key={t} style={{
                fontSize: 12, color: '#ccc', padding: '6px 14px', borderRadius: 999,
                border: '1px solid rgba(255,255,255,0.15)', background: 'rgba(255,255,255,0.04)',
              }}>{t}</span>
            ))}
          </div>
        </div>

        {/* Mascot, centered and cropped at the bottom */}
        <img
          src={mascot}
          alt="PumpQ mascot"
          draggable={false}
          style={{
            position: 'relative', zIndex: 1, marginTop: 'auto', alignSelf: 'center',
            width: 'min(92%, 620px)', marginBottom: '-6%', objectFit: 'contain',
            pointerEvents: 'none', userSelect: 'none', animation: 'pq-rise .8s .15s ease both',
          }}
        />
      </div>

      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#fff', padding: '40px 0' }}>
        <form onSubmit={handleSubmit} style={{ width: 340, animation: 'pq-in .5s ease both' }}>
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
          <div style={{ position: 'relative', marginTop: 6, marginBottom: 16 }}>
            <input
              type={showPassword ? 'text' : 'password'}
              value={form.password}
              onChange={set('password')}
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

          <div style={{ display: 'flex', gap: 12 }}>
            <Field label="Station ID">
              <input type="number" value={form.station_id} onChange={set('station_id')} style={inputStyle} />
            </Field>
            <Field label="Contact number">
              <input value={form.contact_number} onChange={set('contact_number')} style={inputStyle} />
            </Field>
          </div>

          {error && <p style={{ color: '#D8232A', fontSize: 13, marginBottom: 8 }}>{error}</p>}
          <button
            type="submit"
            disabled={loading || leaving}
            onMouseDown={addRipple}
            style={{
              width: '100%', marginTop: 8, padding: 13, position: 'relative', overflow: 'hidden',
              background: 'linear-gradient(135deg,#F5765C,#E8450A)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}
          >
            {ripple && (
              <span key={ripple.key} style={{
                position: 'absolute', left: ripple.x - 120, top: ripple.y - 120, width: 240, height: 240,
                borderRadius: '50%', background: 'rgba(255,255,255,0.45)', pointerEvents: 'none',
                animation: 'pq-ripple .6s ease-out forwards',
              }} />
            )}
            {loading && (
              <span style={{
                width: 14, height: 14, border: '2px solid rgba(255,255,255,0.4)', borderTopColor: '#fff',
                borderRadius: '50%', animation: 'pq-spin .7s linear infinite',
              }} />
            )}
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