import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { DialogProvider } from './context/DialogContext';
import Login from './pages/Login';
import Register from './pages/Register';
import Account from './pages/Account';
import Products from './pages/Products';
import StationServices from './pages/StationServices';
import Layout from './components/Layout';
import Promotions from './pages/Promotions';
import Transactions from './pages/Transactions';
import Notifications from './pages/Notifications';
import Reports from './pages/Reports';
import Dashboard from './pages/Dashboard';
import ScanQr from './pages/ScanQr';

function PrivateRoute({ children }) {
  const { staff } = useAuth();
  return staff ? children : <Navigate to="/login" />;
}

export default function App() {
  return (
    <AuthProvider>
      <DialogProvider>
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
              <Route path="/reports" element={<Reports />} />
              <Route path="/scan" element={<ScanQr />} />
            </Route>
            <Route path="*" element={<Navigate to="/login" />} />
          </Routes>
        </BrowserRouter>
      </DialogProvider>
    </AuthProvider>
  );
}