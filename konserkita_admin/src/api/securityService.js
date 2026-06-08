import api from './axios';

export const securityService = {
  getSessions: async () => {
    const response = await api.get('/security/sessions');
    return response.data;
  },

  revokeSession: async (id) => {
    const response = await api.delete(`/security/sessions/${id}`);
    return response.data;
  },

  revokeOtherSessions: async () => {
    const response = await api.delete('/security/sessions/revoke-others');
    return response.data;
  },

  getLoginActivities: async (page = 1) => {
    const response = await api.get(`/security/login-activities?page=${page}`);
    return response.data;
  }
};
