import axios from 'axios';

const api = axios.create({
  baseURL: '', // Using Vite proxy to /api and /files
  timeout: 15000,
});

// Request interceptor to attach JWT token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('epupuk_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Clear token and redirect to login if unauthorized
      localStorage.removeItem('epupuk_token');
      localStorage.removeItem('epupuk_user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export const authApi = {
  login: (credentials) => api.post('/api/auth/login', credentials),
  getMe: () => api.get('/api/auth/me'),
  logout: () => api.post('/api/auth/logout'),
};

export const applicationsApi = {
  getAll: (params) => api.get('/api/applications', { params }),
  getById: (id) => api.get(`/api/applications/${id}`),
  create: (data) => api.post('/api/applications', data),
  reviseDocs: (id, data) => api.put(`/api/applications/${id}/revise-docs`, null, { params: data }),
  cancel: (id) => api.put(`/api/applications/${id}/cancel`),
  getPetaniStats: () => api.get('/api/applications/stats/petani'),
};

export const adminApi = {
  getStats: () => api.get('/api/admin/stats'),
  getPplOfficers: () => api.get('/api/admin/ppl-officers'),
  verifyDocs: (id, data) => api.post(`/api/admin/applications/${id}/verify-docs`, data),
  assignPpl: (id, data) => api.post(`/api/admin/applications/${id}/assign-ppl`, data),
  finalApprove: (id, data) => api.post(`/api/admin/applications/${id}/final-approve`, data),
  getAuditLogs: () => api.get('/api/admin/audit-logs'),
};

export const pplApi = {
  getAssignedTasks: () => api.get('/api/ppl/assigned-tasks'),
  startSurvey: (id) => api.post(`/api/ppl/applications/${id}/start-survey`),
  submitSurvey: (id, data) => api.post(`/api/ppl/applications/${id}/submit-survey`, data),
};

export const farmersApi = {
  getAll: (params) => api.get('/api/farmers', { params }),
  getMe: () => api.get('/api/farmers/me'),
  getById: (id) => api.get(`/api/farmers/${id}`),
  getGroups: () => api.get('/api/farmer-groups'),
  getCommodities: () => api.get('/api/commodities'),
  getFertilizers: () => api.get('/api/fertilizers'),
};

export const landsApi = {
  getAll: (params) => api.get('/api/lands', { params }),
  getById: (id) => api.get(`/api/lands/${id}`),
  create: (data) => api.post('/api/lands', data),
  update: (id, data) => api.put(`/api/lands/${id}`, data),
  delete: (id) => api.delete(`/api/lands/${id}`),
};

export const filesApi = {
  upload: (file, category) => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('category', category);
    return api.post('/api/files/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
};

export const distributionsApi = {
  getMyDistributions: () => api.get('/api/distributions/my'),
  scanQr: (data) => api.post('/api/distributions/scan-qr', data),
  getNotifications: () => api.get('/api/notifications'),
  markRead: (id) => api.put(`/api/notifications/${id}/read`),
};

export default api;
