import { Link, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { IconHome, IconUser, IconFuel, IconMap, IconTag, IconReceipt, IconBell, IconChart, IconLogout } from './Icons';

const LINKS = [
  { to: '/dashboard', label: 'Dashboard', Icon: IconHome },
  { to: '/account', label: 'My Account', Icon: IconUser },
  { to: '/products', label: 'Products', Icon: IconFuel },
  { to: '/station-services', label: 'Station Services', Icon: IconMap },
  { to: '/promotions', label: 'Promotions', Icon: IconTag },
  { to: '/transactions', label: 'Transactions', Icon: IconReceipt },
  { to: '/notifications', label: 'Notifications', Icon: IconBell },
  { to: '/reports', label: 'Reports', Icon: IconChart },
];

export default function Layout() {
  const { staff, logout } = useAuth();
  const location = useLocation();

  return (
    <div style={{ display: 'flex', height: '100vh' }}>
      <div style={{
        width: 240, background: '#fff', borderRight: '1px solid #ECECEC',
        padding: '28px 18px', display: 'flex', flexDirection: 'column',
        height: '100vh', position: 'sticky', top: 0, flexShrink: 0,
      }}>
        <div style={{ marginBottom: 32, paddingLeft: 6 }}>
          <h2 style={{ fontSize: 19, margin: 0 }}>Pump<span style={{ color: '#E8450A' }}>Q</span></h2>
          <p style={{ fontSize: 11, color: '#999', marginTop: 2 }}>Staff Portal</p>
        </div>
        <nav style={{ flex: 1, overflowY: 'auto' }}>
          {LINKS.map(({ to, label, Icon }) => {
            const active = location.pathname === to;
            return (
              <Link key={to} to={to} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '11px 14px', marginBottom: 2,
                borderRadius: 10, textDecoration: 'none', fontSize: 14, fontWeight: active ? 600 : 500,
                color: active ? '#fff' : '#444',
                background: active ? 'linear-gradient(135deg,#F5765C,#E8450A)' : 'transparent',
                boxShadow: active ? '0 4px 12px rgba(232,69,10,0.25)' : 'none',
              }}>
                <Icon />{label}
              </Link>
            );
          })}
        </nav>
        <button onClick={logout} style={{ background: '#1A1A1A', display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', boxShadow: 'none', marginTop: 16 }}>
          <IconLogout />Logout
        </button>
      </div>
      <div style={{ flex: 1, padding: '36px 44px', overflowY: 'auto', height: '100vh' }}>
        <Outlet />
      </div>
    </div>
  );
}