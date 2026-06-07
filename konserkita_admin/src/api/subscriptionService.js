import axiosInstance from './axiosInstance';

export const getSubscriptionPlans = async () => {
    const response = await axiosInstance.get('/admin/subscription-plans');
    return response.data;
};

export const createSubscriptionPlan = async (data) => {
    const response = await axiosInstance.post('/admin/subscription-plans', data);
    return response.data;
};

export const updateSubscriptionPlan = async (id, data) => {
    const response = await axiosInstance.put(`/admin/subscription-plans/${id}`, data);
    return response.data;
};

export const deleteSubscriptionPlan = async (id) => {
    const response = await axiosInstance.delete(`/admin/subscription-plans/${id}`);
    return response.data;
};

export const getSubscriptions = async () => {
    const response = await axiosInstance.get('/admin/subscriptions');
    return response.data;
};
