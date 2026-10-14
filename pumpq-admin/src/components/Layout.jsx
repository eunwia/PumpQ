import { Link, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { IconHome, IconUser, IconFuel, IconMap, IconTag, IconReceipt, IconBell, IconChart, IconLogout } from './Icons';
import navLogo from '../../images/pumpq-nav-logo.png';

const LINKS = [
  { to: '/dashboard', label: 'Dashboard', Icon: IconHome },
  { to: '/scan', label: 'Scan QR', Icon: IconFuel },
  { to: '/transactions', label: 'Orders', Icon: IconReceipt },
  { to: '/products', label: 'Products', Icon: IconFuel },
  { to: '/promotions', label: 'Promotions', Icon: IconTag },
  { to: '/station-services', label: 'Station Services', Icon: IconMap },
  { to: '/notifications', label: 'Notifications', Icon: IconBell },
  { to: '/reports', label: 'Reports', Icon: IconChart },
  { to: '/account', label: 'My Account', Icon: IconUser },
];

export default function Layout() {
  const { staff, logout } = useAuth();
  const location = useLocation();

  return (
    <div style={{ display: 'flex', height: '100vh' }}>
      <div style={{
        width: 240, background: '#111', borderRight: '1px solid #222',
        padding: '28px 18px', display: 'flex', flexDirection: 'column',
        height: '100vh', position: 'sticky', top: 0, flexShrink: 0,
      }}>
        <div style={{ marginBottom: 32, paddingLeft: 6 }}>
          <img src={navLogo} alt="PumpQ" draggable={false} style={{ height: 26, display: 'block', objectFit: 'contain' }} />
          <p style={{ fontSize: 11, color: '#888', marginTop: 2 }}>Staff Portal</p>
        </div>
        <nav style={{ flex: 1, overflowY: 'auto' }}>
          {LINKS.map(({ to, label, Icon }) => {
            const active = location.pathname === to;
            return (
              <Link key={to} to={to} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '11px 14px', marginBottom: 2,
                borderRadius: 10, textDecoration: 'none', fontSize: 14, fontWeight: active ? 600 : 500,
                color: active ? '#fff' : '#B5B5B5',
                background: active ? 'linear-gradient(135deg,#F5765C,#E8450A)' : 'transparent',
                boxShadow: active ? '0 4px 12px rgba(232,69,10,0.25)' : 'none',
              }}>
                <Icon />{label}
              </Link>
            );
          })}
        </nav>
        <button onClick={logout} style={{ background: '#2A2A2A', border: '1px solid #333', display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', boxShadow: 'none', marginTop: 16 }}>
          <IconLogout />Logout
        </button>
      </div>
      <div style={{ flex: 1, padding: '36px 44px', overflowY: 'auto', height: '100vh' }}>
        <Outlet />
      </div>
    </div>
  );
}