import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './pages/Login';
import Register from './pages/Register';
import Account from './pages/Account';
import Products from './pages/Products';
import StationServices from './pages/StationServices';
import Layout from './components/Layout';
import Promotions from './pages/Promotions';
import Transactions from './pages/Transactions';
import Notifications from './pages/Notifications';

function Dashboard() {
  const { staff } = useAuth();
  return <div><h2>Dashboard</h2><p>Welcome, {staff?.first_name}!</p></div>;
}

function PrivateRoute({ children }) {
  const { staff } = useAuth();
  return staff ? children : <Navigate to="/login" />;
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route element={<PrivateRoute><Layout /></PrivateRoute>}>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/account" element={<Account />} />
            <Route path="/products" element={<Products />} />
            <Route path="/station-services" element={<StationServices />} />
            <Route path="/promotions" element={<Promotions />} />
            <Route path="/transactions" element={<Transactions />} />
            <Route path="/notifications" element={<Notifications />} />          
          </Route>
          <Route path="*" element={<Navigate to="/login" />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}