import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../api/axios';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      const token = localStorage.getItem('token');
      if (token) {
        try {
          const response = await api.get('/profile');
          if (response.data.success) {
            setUser(response.data.data);
          } else {
            localStorage.removeItem('token');
          }
        } catch (error) {
          localStorage.removeItem('token');
        }
      }
      setLoading(false);
    };
    checkAuth();
  }, []);

  const login = async (email, password) => {
    try {
      const response = await api.post('/login', { email, password });
      // Normal login returns response.data.data.token, 
      // but requires_2fa returns response.data.requires_2fa
      if (response.data.requires_2fa) {
        return { success: true, requires2FA: true, temporaryToken: response.data.temporary_token };
      }

      if (response.data.success) {
        const { token, user } = response.data.data;
        if (user.role === 'admin' || user.role === 'super_admin') {
          localStorage.setItem('token', token);
          setUser(user);
          return { success: true };
        } else {
          return { success: false, message: 'Unauthorized. Admins only.' };
        }
      }
      return { success: false, message: response.data.message };
    } catch (error) {
      return { success: false, message: error.response?.data?.message || 'Login failed' };
    }
  };

  const socialLogin = async (accessToken, provider) => {
    try {
      const response = await api.post(`/auth/${provider}`, { access_token: accessToken });
      if (response.data.requires_2fa) {
        return { success: true, requires2FA: true, temporaryToken: response.data.temporary_token };
      }

      if (response.data.success) {
        const { token, user } = response.data.data;
        if (user.role === 'admin' || user.role === 'super_admin') {
          localStorage.setItem('token', token);
          setUser(user);
          return { success: true };
        } else {
          return { success: false, message: 'Unauthorized. Admins only.' };
        }
      }
      return { success: false, message: response.data.message };
    } catch (error) {
      return { success: false, message: error.response?.data?.message || 'Social login failed' };
    }
  };

  const passkeyLogin = async (data) => {
    try {
      const response = await api.post('/passkeys/login/verify', data);
      if (response.data.requires_2fa) {
        return { success: true, requires2FA: true, temporaryToken: response.data.temporary_token };
      }

      if (response.data.message === 'Login successful') {
        const { token, user } = response.data;
        if (user.role === 'admin' || user.role === 'super_admin') {
          localStorage.setItem('token', token);
          setUser(user);
          return { success: true };
        } else {
          return { success: false, message: 'Unauthorized. Admins only.' };
        }
      }
      return { success: false, message: response.data.message || 'Passkey login failed' };
    } catch (error) {
      return { success: false, message: error.response?.data?.message || 'Passkey login failed' };
    }
  };

  const verify2FA = async (temporaryToken, code, isRecovery = false) => {
    try {
      const payload = { temporary_token: temporaryToken };
      if (isRecovery) {
        payload.recovery_code = code;
      } else {
        payload.code = code;
      }
      
      const response = await api.post('/2fa/challenge', payload);
      if (response.data.message === 'Login successful') {
        const { token, user } = response.data;
        if (user.role === 'admin' || user.role === 'super_admin') {
          localStorage.setItem('token', token);
          setUser(user);
          return { success: true };
        } else {
          return { success: false, message: 'Unauthorized. Admins only.' };
        }
      }
      return { success: false, message: response.data.message || 'Invalid code' };
    } catch (error) {
      return { success: false, message: error.response?.data?.message || 'Verification failed' };
    }
  };

  const logout = async () => {
    try {
      await api.post('/logout');
    } catch (error) {
      console.error('Logout error', error);
    } finally {
      localStorage.removeItem('token');
      setUser(null);
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, socialLogin, passkeyLogin, verify2FA }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
