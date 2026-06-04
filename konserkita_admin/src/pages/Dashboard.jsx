import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { Users, Calendar, Briefcase, CreditCard, DollarSign, Clock, RefreshCcw } from 'lucide-react';

const Dashboard = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchDashboard = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/dashboard');
      if (response.data.success) {
        setData(response.data.data);
      } else {
        setError(response.data.message);
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to fetch dashboard data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboard();
  }, []);

  if (loading) {
    return <div className="flex justify-center items-center h-full"><RefreshCcw className="animate-spin text-[#6C2BD9]" size={32} /></div>;
  }

  if (error) {
    return <div className="text-red-500 p-4 bg-red-50 rounded-lg">{error}</div>;
  }

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount);
  };

  const statCards = [
    { title: 'Total Users', value: data?.total_users || 0, icon: <Users size={24} className="text-blue-500" />, bg: 'bg-blue-50' },
    { title: 'Total Organizers', value: data?.total_organizers || 0, icon: <Briefcase size={24} className="text-purple-500" />, bg: 'bg-purple-50' },
    { title: 'Total Events', value: data?.total_events || 0, icon: <Calendar size={24} className="text-pink-500" />, bg: 'bg-pink-50' },
    { title: 'Pending Events', value: data?.pending_events || 0, icon: <Clock size={24} className="text-orange-500" />, bg: 'bg-orange-50' },
    { title: 'Transactions', value: data?.total_transactions || 0, icon: <CreditCard size={24} className="text-green-500" />, bg: 'bg-green-50' },
    { title: 'Total Revenue', value: formatCurrency(data?.total_revenue || 0), icon: <DollarSign size={24} className="text-emerald-500" />, bg: 'bg-emerald-50' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">Dashboard</h1>
        <button onClick={fetchDashboard} className="p-2 text-gray-500 hover:text-[#6C2BD9] bg-white rounded-full shadow-sm">
          <RefreshCcw size={20} />
        </button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {statCards.map((stat, idx) => (
          <div key={idx} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 flex items-center">
            <div className={`p-4 rounded-full ${stat.bg} mr-4`}>
              {stat.icon}
            </div>
            <div>
              <p className="text-sm font-medium text-gray-500">{stat.title}</p>
              <h3 className="text-2xl font-bold text-gray-800">{stat.value}</h3>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Transactions placeholder */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <h2 className="text-lg font-bold text-gray-800 mb-4">Recent Transactions</h2>
        {data?.recent_transactions && data.recent_transactions.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {data.recent_transactions.map((trx) => (
                  <tr key={trx.id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{trx.order_id}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{trx.user?.name || 'Unknown'}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{formatCurrency(trx.total_amount)}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                      <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        trx.payment_status === 'success' ? 'bg-green-100 text-green-800' : 
                        trx.payment_status === 'pending' ? 'bg-yellow-100 text-yellow-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {trx.payment_status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="text-gray-500 text-center py-4">No recent transactions.</p>
        )}
      </div>
    </div>
  );
};

export default Dashboard;
