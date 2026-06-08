import api from './axios';

export const getSubscriptionPlans = async () => {
    const response = await api.get('/admin/subscription-plans');
    return response.data;
};

export const createSubscriptionPlan = async (data) => {
    const response = await api.post('/admin/subscription-plans', data);
    return response.data;
};

export const updateSubscriptionPlan = async (id, data) => {
    const response = await api.put(`/admin/subscription-plans/${id}`, data);
    return response.data;
};

export const deleteSubscriptionPlan = async (id) => {
    const response = await api.delete(`/admin/subscription-plans/${id}`);
    return response.data;
};

export const getSubscriptions = async () => {
    const response = await api.get('/admin/subscriptions');
    return response.data;
};
