import React, { useState, useEffect } from 'react';
import { getSubscriptionPlans, createSubscriptionPlan, updateSubscriptionPlan, deleteSubscriptionPlan } from '../api/subscriptionService';
import { toast } from 'react-hot-toast';
import { useTranslation } from 'react-i18next';

const SubscriptionPlans = () => {
    const { t } = useTranslation();
    const [plans, setPlans] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [formData, setFormData] = useState({
        name: '',
        slug: '',
        price: '',
        billing_cycle: 'monthly',
        max_events: '',
        max_tickets_per_event: '',
        max_admin_users: '',
        platform_fee_percentage: '',
        features: {
            event_creation: true,
            ticket_sales: true,
            analytics: false,
            custom_domain: false
        },
        status: 'active'
    });
    const [editId, setEditId] = useState(null);

    useEffect(() => {
        fetchPlans();
    }, []);

    const fetchPlans = async () => {
        try {
            const data = await getSubscriptionPlans();
            setPlans(data.data);
            setLoading(false);
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to fetch plans');
            setLoading(false);
        }
    };

    const handleInputChange = (e) => {
        const { name, value, type, checked } = e.target;
        if (name.startsWith('features.')) {
            const featureName = name.split('.')[1];
            setFormData({
                ...formData,
                features: {
                    ...formData.features,
                    [featureName]: checked
                }
            });
        } else {
            setFormData({ ...formData, [name]: type === 'checkbox' ? checked : value });
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editId) {
                await updateSubscriptionPlan(editId, formData);
                toast.success('Plan updated successfully');
            } else {
                await createSubscriptionPlan(formData);
                toast.success('Plan created successfully');
            }
            setShowModal(false);
            fetchPlans();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to save plan');
        }
    };

    const handleEdit = (plan) => {
        setFormData(plan);
        setEditId(plan.id);
        setShowModal(true);
    };

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this plan?')) {
            try {
                await deleteSubscriptionPlan(id);
                toast.success('Plan deleted successfully');
                fetchPlans();
            } catch (error) {
                toast.error(error.response?.data?.message || 'Failed to delete plan');
            }
        }
    };

    const openModal = () => {
        setFormData({
            name: '',
            slug: '',
            price: '',
            billing_cycle: 'monthly',
            max_events: '',
            max_tickets_per_event: '',
            max_admin_users: '',
            platform_fee_percentage: '',
            features: {
                event_creation: true,
                ticket_sales: true,
                analytics: false,
                custom_domain: false
            },
            status: 'active'
        });
        setEditId(null);
        setShowModal(true);
    };

    if (loading) return <div className="p-4">Loading...</div>;

    return (
        <div className="p-6">
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-white/90">Subscription Plans</h1>
                <button 
                    onClick={openModal}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
                >
                    Create Plan
                </button>
            </div>

            <div className="bg-[#141416] border border-white/5 rounded-lg shadow overflow-hidden">
                <table className="min-w-full divide-y divide-white/10">
                    <thead className="bg-[#1C1C1F]">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Name</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Price / Cycle</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Limits</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Platform Fee</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Status</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                        {plans.map((plan) => (
                            <tr key={plan.id}>
                                <td className="px-6 py-4 whitespace-nowrap">
                                    <div className="font-medium text-white">{plan.name}</div>
                                    <div className="text-sm text-white/60">{plan.slug}</div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                    Rp {Number(plan.price).toLocaleString()} / {plan.billing_cycle}
                                </td>
                                <td className="px-6 py-4">
                                    <div className="text-sm">Events: {plan.max_events}</div>
                                    <div className="text-sm">Tickets: {plan.max_tickets_per_event}</div>
                                    <div className="text-sm">Admins: {plan.max_admin_users}</div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                    {plan.platform_fee_percentage}%
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${plan.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                                        {plan.status}
                                    </span>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                    <button onClick={() => handleEdit(plan)} className="text-indigo-600 hover:text-indigo-900 mr-3">Edit</button>
                                    <button onClick={() => handleDelete(plan.id)} className="text-red-600 hover:text-red-900">Delete</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {showModal && (
                <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full flex justify-center items-center">
                    <div className="bg-[#141416] border border-white/5 p-6 rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
                        <h2 className="text-xl font-bold mb-4">{editId ? 'Edit Plan' : 'Create Plan'}</h2>
                        <form onSubmit={handleSubmit}>
                            <div className="grid grid-cols-2 gap-4">
                                <div className="mb-4">
                                    <label className="block text-white/80 text-sm font-bold mb-2">Name</label>
                                    <input type="text" name="name" value={formData.name} onChange={handleInputChange} className="w-full border p-2 rounded" required />
                                </div>
                                <div className="mb-4">
                                    <label className="block text-white/80 text-sm font-bold mb-2">Slug</label>
                                    <input type="text" name="slug" value={formData.slug} onChange={handleInputChange} className="w-full border p-2 rounded" required />
                                </div>
                                <div className="mb-4">
                                    <label className="block text-white/80 text-sm font-bold mb-2">Price</label>
                                    <input type="number" name="price" value={formData.price} onChange={handleInputChange} className="w-full border p-2 rounded" required />
                                </div>
                                <div className="mb-4">
                                    <label className="block text-white/80 text-sm font-bold mb-2">Billing Cycle</label>
                                    <select name="billing_cycle" value={formData.billing_cycle} onChange={handleInputChange} className="w-full border p-2 rounded">
                                        <option value="monthly">Monthly</option>
                                        <option value="yearly">Yearly</option>
                                    </select>
                                </div>
                                <div className="mb-4">
                                    <label className="block text-white/80 text-sm font-bold mb-2">Max Events/Month</label>
                                    <input type="number" name="max_events" value={formData.max_events} onChange={handleInputChange} className="w-full border p-2 rounded" required />
                                </div>
                                <div className="mb-4">
                                    <label className="block text-white/80 text-sm font-bold mb-2">Max Tickets/Event</label>
                                    <input type="number" name="max_tickets_per_event" value={formData.max_tickets_per_event} onChange={handleInputChange} className="w-full border p-2 rounded" required />
                                </div>
                                <div className="mb-4">
                                    <label className="block text-white/80 text-sm font-bold mb-2">Max Admin Users</label>
                                    <input type="number" name="max_admin_users" value={formData.max_admin_users} onChange={handleInputChange} className="w-full border p-2 rounded" required />
                                </div>
                                <div className="mb-4">
                                    <label className="block text-white/80 text-sm font-bold mb-2">Platform Fee (%)</label>
                                    <input type="number" step="0.01" name="platform_fee_percentage" value={formData.platform_fee_percentage} onChange={handleInputChange} className="w-full border p-2 rounded" required />
                                </div>
                            </div>
                            
                            <div className="mb-4">
                                <label className="block text-white/80 text-sm font-bold mb-2">Status</label>
                                <select name="status" value={formData.status} onChange={handleInputChange} className="w-full border p-2 rounded">
                                    <option value="active">Active</option>
                                    <option value="inactive">Inactive</option>
                                </select>
                            </div>

                            <div className="mb-4">
                                <label className="block text-white/80 text-sm font-bold mb-2">Features</label>
                                <div className="space-y-2">
                                    <label className="flex items-center">
                                        <input type="checkbox" name="features.analytics" checked={formData.features.analytics} onChange={handleInputChange} className="mr-2" />
                                        Advanced Analytics
                                    </label>
                                    <label className="flex items-center">
                                        <input type="checkbox" name="features.custom_domain" checked={formData.features.custom_domain} onChange={handleInputChange} className="mr-2" />
                                        Custom Domain
                                    </label>
                                </div>
                            </div>

                            <div className="flex justify-end mt-6">
                                <button type="button" onClick={() => setShowModal(false)} className="bg-gray-400 text-white px-4 py-2 rounded mr-2 hover:bg-[#1C1C1F]0">Cancel</button>
                                <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">Save</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default SubscriptionPlans;
