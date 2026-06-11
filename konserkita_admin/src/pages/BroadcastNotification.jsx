import React, { useState } from 'react';
import { Send, Users, UserCheck, Shield } from 'lucide-react';
import api from '../api/axios';
import toast from 'react-hot-toast';

const BroadcastNotification = () => {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    message: '',
    target: 'all',
    event_id: ''
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title || !formData.message) {
      toast.error('Title and Message are required');
      return;
    }

    try {
      setLoading(true);
      await api.post('/admin/notifications/broadcast', formData);
      toast.success('Broadcast notification sent successfully!');
      setFormData({ ...formData, title: '', message: '' });
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to send broadcast');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white">Broadcast Notification</h1>
      </div>

      <div className="bg-[#141416] border border-white/5 rounded-xl shadow-sm overflow-hidden">
        <div className="p-6">
          <form onSubmit={handleSubmit} className="space-y-6">
            
            <div>
              <label className="block text-sm font-medium text-white/80 mb-1">Target Audience</label>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[
                  { id: 'all', name: 'All Users', icon: Users },
                  { id: 'customers', name: 'Customers', icon: UserCheck },
                  { id: 'organizers', name: 'Organizers', icon: Users },
                  { id: 'admins', name: 'Admins', icon: Shield },
                ].map((target) => {
                  const Icon = target.icon;
                  return (
                    <div
                      key={target.id}
                      onClick={() => setFormData({ ...formData, target: target.id })}
                      className={`cursor-pointer border rounded-lg p-4 flex flex-col items-center justify-center space-y-2 transition-colors ${
                        formData.target === target.id
                          ? 'border-indigo-600 bg-indigo-50 text-indigo-700'
                          : 'border-white/10 hover:border-indigo-300 text-white/70'
                      }`}
                    >
                      <Icon className="h-6 w-6" />
                      <span className="font-medium">{target.name}</span>
                    </div>
                  );
                })}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-white/80 mb-1">Notification Title</label>
              <input
                type="text"
                name="title"
                value={formData.title}
                onChange={handleChange}
                placeholder="e.g. Special Promo Code!"
                className="w-full rounded-md border-white/20 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-white/80 mb-1">Message Body</label>
              <textarea
                name="message"
                value={formData.message}
                onChange={handleChange}
                rows={4}
                placeholder="Enter your broadcast message here..."
                className="w-full rounded-md border-white/20 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                required
              />
            </div>

            <div className="flex justify-end pt-4">
              <button
                type="submit"
                disabled={loading}
                className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
              >
                {loading ? (
                  <span className="flex items-center">
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Sending...
                  </span>
                ) : (
                  <span className="flex items-center">
                    <Send className="w-4 h-4 mr-2" />
                    Send Broadcast
                  </span>
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default BroadcastNotification;
