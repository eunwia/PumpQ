import { Link, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Layout() {
  const { staff, logout } = useAuth();
  const navStyle = { display: 'block', padding: '10px 0', color: '#333', textDecoration: 'none' };

  return (
    <div style={{ display: 'flex', fontFamily: 'sans-serif', minHeight: '100vh' }}>
      <div style={{ width: 220, background: '#FFF0EA', padding: 20 }}>
        <h3 style={{ color: '#E8450A' }}>PumpQ Staff</h3>
        <p style={{ fontSize: 13, color: '#666' }}>{staff?.first_name} {staff?.last_name}</p>
        <nav>
          <Link style={navStyle} to="/dashboard">Dashboard</Link>
          <Link style={navStyle} to="/account">My Account</Link>
          <Link style={navStyle} to="/products">Products</Link>
          <Link style={navStyle} to="/station-services">Station Services</Link>
          <Link style={navStyle} to="/promotions">Promotions</Link>
          <Link style={navStyle} to="/transactions">Transactions</Link>
          <Link style={navStyle} to="/notifications">Notifications</Link>        
        </nav>
        <button onClick={logout} style={{ marginTop: 20 }}>Logout</button>
      </div>
      <div style={{ flex: 1, padding: 30 }}>
        <Outlet />
      </div>
    </div>
  );
}