import { create } from 'zustand';
import { authApi } from '../services/api';

export const useAuthStore = create((set, get) => ({
  user: null,
  token: null,
  isAuthenticated: false,
  isLoading: true,

  initAuth: () => {
    try {
      const storedToken = localStorage.getItem('epupuk_token');
      const storedUser = localStorage.getItem('epupuk_user');
      if (storedToken && storedUser) {
        set({
          token: storedToken,
          user: JSON.parse(storedUser),
          isAuthenticated: true,
          isLoading: false,
        });
      } else {
        set({ user: null, token: null, isAuthenticated: false, isLoading: false });
      }
    } catch (e) {
      set({ user: null, token: null, isAuthenticated: false, isLoading: false });
    }
  },

  login: async (username, password) => {
    set({ isLoading: true });
    try {
      const res = await authApi.login({ username, password });
      const { access_token, role, user_id, username: uName, nama, farmer_id } = res.data;
      const userData = { user_id, username: uName, role, nama, farmer_id };

      localStorage.setItem('epupuk_token', access_token);
      localStorage.setItem('epupuk_user', JSON.stringify(userData));

      set({
        token: access_token,
        user: userData,
        isAuthenticated: true,
        isLoading: false,
      });
      return { success: true, user: userData };
    } catch (err) {
      set({ isLoading: false });
      const msg = err.response?.data?.detail || 'Gagal masuk. Periksa username dan password Anda.';
      return { success: false, error: msg };
    }
  },

  logout: async () => {
    try {
      await authApi.logout();
    } catch (e) {
      // Ignore error on logout
    } finally {
      localStorage.removeItem('epupuk_token');
      localStorage.removeItem('epupuk_user');
      set({ user: null, token: null, isAuthenticated: false, isLoading: false });
    }
  },
}));
