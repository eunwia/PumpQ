import { createContext, useContext, useState } from 'react';
import api from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [staff, setStaff] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  async function login(email, password) {
    setLoading(true);
    setError(null);
    try {
      const res = await api.post('/staff/auth/login', { email, password });
      localStorage.setItem('staff_token', res.data.data.token);
      setStaff(res.data.data.staff);
      return true;
    } catch (e) {
      setError(e.response?.data?.message || 'Login failed');
      return false;
    } finally {
      setLoading(false);
    }
  }

  function logout() {
    localStorage.removeItem('staff_token');
    setStaff(null);
  }

  return (
    <AuthContext.Provider value={{ staff, error, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}