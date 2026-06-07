import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { 
  Share2, CheckCircle, XCircle, DollarSign, Activity, Users,
  AlertCircle
} from 'lucide-react';

const Referrals = () => {
  const [activeTab, setActiveTab] = useState('stats');
  const [stats, setStats] = useState(null);
  const [rewards, setRewards] = useState([]);
  const [codes, setCodes] = useState([]);
  const [conversions, setConversions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'stats') {
        const res = await api.get('/admin/referrals/stats');
        setStats(res.data.data);
      } else if (activeTab === 'rewards') {
        const res = await api.get('/admin/referrals/rewards');
        setRewards(res.data.data.data);
      } else if (activeTab === 'codes') {
        const res = await api.get('/admin/referrals/codes');
        setCodes(res.data.data.data);
      } else if (activeTab === 'conversions') {
        const res = await api.get('/admin/referrals/conversions');
        setConversions(res.data.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleApproveReward = async (id) => {
    if (!window.confirm('Approve this reward?')) return;
    try {
      await api.post(`/admin/referrals/rewards/${id}/approve`);
      fetchData();
    } catch (error) {
      alert(error.response?.data?.message || 'Error approving reward');
    }
  };

  const handleRejectReward = async (id) => {
    if (!window.confirm('Reject this reward?')) return;
    try {
      await api.post(`/admin/referrals/rewards/${id}/reject`);
      fetchData();
    } catch (error) {
      alert(error.response?.data?.message || 'Error rejecting reward');
    }
  };

  const handleMarkPaid = async (id) => {
    if (!window.confirm('Mark this reward as paid?')) return;
    try {
      await api.post(`/admin/referrals/rewards/${id}/mark-paid`);
      fetchData();
    } catch (error) {
      alert(error.response?.data?.message || 'Error marking reward as paid');
    }
  };

  const renderStats = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">Total Conversions</p>
              <h3 className="text-2xl font-bold text-gray-900 mt-1">{stats?.total_conversions || 0}</h3>
            </div>
            <div className="h-12 w-12 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-600">
              <Activity size={24} />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">Pending Commissions</p>
              <h3 className="text-2xl font-bold text-gray-900 mt-1">Rp {stats?.pending_commission?.toLocaleString('id-ID') || 0}</h3>
            </div>
            <div className="h-12 w-12 rounded-full bg-amber-100 flex items-center justify-center text-amber-600">
              <DollarSign size={24} />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">Paid Commissions</p>
              <h3 className="text-2xl font-bold text-gray-900 mt-1">Rp {stats?.paid_commission?.toLocaleString('id-ID') || 0}</h3>
            </div>
            <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center text-green-600">
              <CheckCircle size={24} />
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-100">
          <h3 className="text-lg font-semibold text-gray-900">Top Referrers</h3>
        </div>
        <div className="divide-y divide-gray-100">
          {stats?.top_referrers?.map((ref) => (
            <div key={ref.id} className="p-4 flex items-center justify-between hover:bg-gray-50 transition-colors">
              <div className="flex items-center space-x-4">
                <div className="h-10 w-10 rounded-full bg-[#6C2BD9]/10 flex items-center justify-center text-[#6C2BD9] font-bold">
                  {ref.user?.name?.charAt(0).toUpperCase()}
                </div>
                <div>
                  <h4 className="text-sm font-semibold text-gray-900">{ref.user?.name}</h4>
                  <p className="text-xs text-gray-500">{ref.code}</p>
                </div>
              </div>
              <div className="text-right">
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  {ref.used_count} Uses
                </span>
              </div>
            </div>
          ))}
          {stats?.top_referrers?.length === 0 && (
            <div className="p-8 text-center text-gray-500">No referrers yet.</div>
          )}
        </div>
      </div>
    </div>
  );

  const renderRewards = () => (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-100">
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Referrer</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Transaction ID</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Amount</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Status</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {rewards.map((reward) => (
              <tr key={reward.id} className="hover:bg-gray-50/50">
                <td className="p-4">
                  <div className="font-medium text-gray-900">{reward.user?.name}</div>
                  <div className="text-xs text-gray-500">{reward.user?.email}</div>
                </td>
                <td className="p-4 text-sm text-gray-600">
                  {reward.conversion?.transaction_id}
                </td>
                <td className="p-4 font-medium text-gray-900">
                  Rp {parseInt(reward.amount).toLocaleString('id-ID')}
                </td>
                <td className="p-4">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    reward.status === 'pending' ? 'bg-amber-100 text-amber-800' :
                    reward.status === 'approved' ? 'bg-blue-100 text-blue-800' :
                    reward.status === 'paid' ? 'bg-green-100 text-green-800' :
                    'bg-red-100 text-red-800'
                  }`}>
                    {reward.status.toUpperCase()}
                  </span>
                </td>
                <td className="p-4 text-right space-x-2">
                  {reward.status === 'pending' && (
                    <>
                      <button onClick={() => handleApproveReward(reward.id)} className="text-blue-600 hover:text-blue-900 font-medium text-sm">Approve</button>
                      <button onClick={() => handleRejectReward(reward.id)} className="text-red-600 hover:text-red-900 font-medium text-sm">Reject</button>
                    </>
                  )}
                  {reward.status === 'approved' && (
                    <button onClick={() => handleMarkPaid(reward.id)} className="text-green-600 hover:text-green-900 font-medium text-sm">Mark Paid</button>
                  )}
                </td>
              </tr>
            ))}
            {rewards.length === 0 && (
              <tr>
                <td colSpan="5" className="p-8 text-center text-gray-500">No rewards found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );

  const renderCodes = () => (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-100">
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Code</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">User</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Type & Comm</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Uses</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {codes.map((code) => (
              <tr key={code.id} className="hover:bg-gray-50/50">
                <td className="p-4">
                  <span className="font-mono bg-gray-100 px-2 py-1 rounded text-sm text-gray-800">{code.code}</span>
                </td>
                <td className="p-4">
                  <div className="font-medium text-gray-900">{code.user?.name}</div>
                  <div className="text-xs text-gray-500">{code.user?.email}</div>
                </td>
                <td className="p-4">
                  <div className="text-sm text-gray-900">{code.type}</div>
                  <div className="text-xs text-gray-500">
                    {code.commission_type === 'percentage' ? `${code.commission_value}%` : `Rp ${code.commission_value}`}
                  </div>
                </td>
                <td className="p-4 text-sm text-gray-600">
                  {code.used_count} / {code.usage_limit || '∞'}
                </td>
                <td className="p-4">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    code.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                  }`}>
                    {code.status.toUpperCase()}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );

  const renderConversions = () => (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-100">
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Referrer</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Buyer</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Transaction ID</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Commission</th>
              <th className="p-4 text-xs font-semibold text-gray-500 uppercase">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {conversions.map((conv) => (
              <tr key={conv.id} className="hover:bg-gray-50/50">
                <td className="p-4">
                  <div className="font-medium text-gray-900">{conv.referral_code?.user?.name}</div>
                  <div className="text-xs text-gray-500">{conv.referral_code?.code}</div>
                </td>
                <td className="p-4">
                  <div className="font-medium text-gray-900">{conv.referred_user?.name || 'Guest'}</div>
                </td>
                <td className="p-4 text-sm text-gray-600">
                  {conv.transaction_id}
                </td>
                <td className="p-4 font-medium text-gray-900">
                  Rp {parseInt(conv.commission_amount).toLocaleString('id-ID')}
                </td>
                <td className="p-4">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    conv.status === 'pending' ? 'bg-amber-100 text-amber-800' :
                    conv.status === 'approved' ? 'bg-blue-100 text-blue-800' :
                    conv.status === 'paid' ? 'bg-green-100 text-green-800' :
                    'bg-red-100 text-red-800'
                  }`}>
                    {conv.status.toUpperCase()}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Referrals Management</h1>
          <p className="text-gray-500 text-sm mt-1">Manage affiliate codes, track conversions, and approve commissions.</p>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-2 flex space-x-2">
        <button
          onClick={() => setActiveTab('stats')}
          className={`flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'stats' ? 'bg-[#6C2BD9] text-white' : 'text-gray-600 hover:bg-gray-100'
          }`}
        >
          <Activity size={18} className="mr-2" />
          Dashboard Stats
        </button>
        <button
          onClick={() => setActiveTab('rewards')}
          className={`flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'rewards' ? 'bg-[#6C2BD9] text-white' : 'text-gray-600 hover:bg-gray-100'
          }`}
        >
          <DollarSign size={18} className="mr-2" />
          Rewards & Payouts
        </button>
        <button
          onClick={() => setActiveTab('codes')}
          className={`flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'codes' ? 'bg-[#6C2BD9] text-white' : 'text-gray-600 hover:bg-gray-100'
          }`}
        >
          <Share2 size={18} className="mr-2" />
          Referral Codes
        </button>
        <button
          onClick={() => setActiveTab('conversions')}
          className={`flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
            activeTab === 'conversions' ? 'bg-[#6C2BD9] text-white' : 'text-gray-600 hover:bg-gray-100'
          }`}
        >
          <CheckCircle size={18} className="mr-2" />
          Conversions
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center items-center py-20">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#6C2BD9]"></div>
        </div>
      ) : (
        <>
          {activeTab === 'stats' && renderStats()}
          {activeTab === 'rewards' && renderRewards()}
          {activeTab === 'codes' && renderCodes()}
          {activeTab === 'conversions' && renderConversions()}
        </>
      )}
    </div>
  );
};

export default Referrals;
