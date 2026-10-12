import { Link, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const LINKS = [
  { to: '/dashboard', label: 'Dashboard', icon: '🏠' },
  { to: '/account', label: 'My Account', icon: '👤' },
  { to: '/products', label: 'Products', icon: '⛽' },
  { to: '/station-services', label: 'Station Services', icon: '🗺️' },
  { to: '/promotions', label: 'Promotions', icon: '🏷️' },
  { to: '/transactions', label: 'Transactions', icon: '🧾' },
  { to: '/notifications', label: 'Notifications', icon: '🔔' },
  { to: '/reports', label: 'Reports', icon: '📊' },
];

export default function Layout() {
  const { staff, logout } = useAuth();
  const location = useLocation();

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <div style={{ width: 230, background: '#fff', borderRight: '1px solid #eee', padding: '24px 16px', display: 'flex', flexDirection: 'column' }}>
        <div style={{ marginBottom: 28 }}>
          <h2 style={{ color: '#E8450A', margin: 0, fontSize: 20 }}>⛽ PumpQ Staff</h2>
          <p style={{ fontSize: 12, color: '#999', margin: '4px 0 0' }}>{staff?.first_name} {staff?.last_name}</p>
        </div>
        <nav style={{ flex: 1 }}>
          {LINKS.map((l) => {
            const active = location.pathname === l.to;
            return (
              <Link
                key={l.to}
                to={l.to}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  padding: '10px 12px',
                  marginBottom: 4,
                  borderRadius: 8,
                  textDecoration: 'none',
                  fontSize: 14,
                  fontWeight: active ? 600 : 500,
                  color: active ? '#E8450A' : '#444',
                  background: active ? '#FFF0EA' : 'transparent',
                }}
              >
                <span>{l.icon}</span>{l.label}
              </Link>
            );
          })}
        </nav>
        <button onClick={logout} style={{ background: '#f0f0f0', color: '#444', width: '100%' }}>Logout</button>
      </div>
      <div style={{ flex: 1, padding: '32px 40px' }}>
        <Outlet />
      </div>
    </div>
  );
}