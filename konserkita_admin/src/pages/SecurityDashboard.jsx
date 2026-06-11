import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { 
  ShieldAlert, 
  Lock, 
  Unlock, 
  RefreshCw, 
  AlertTriangle,
  MonitorSmartphone,
  Globe,
  Activity
} from 'lucide-react';
import toast from 'react-hot-toast';

const SecurityDashboard = () => {
  const [activeTab, setActiveTab] = useState('alerts');
  const [alerts, setAlerts] = useState([]);
  const [lockedAccounts, setLockedAccounts] = useState([]);
  const [abuseLogs, setAbuseLogs] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'alerts') {
        const response = await api.get('/admin/security/alerts');
        setAlerts(response.data.data || response.data);
      } else if (activeTab === 'locked-accounts') {
        const response = await api.get('/admin/security/locked-accounts');
        setLockedAccounts(response.data.data || response.data);
      } else if (activeTab === 'api-abuse-logs') {
        const response = await api.get('/admin/security/api-abuse-logs');
        setAbuseLogs(response.data.data.data || response.data.data || response.data);
      }
    } catch (error) {
      toast.error('Failed to fetch security data');
    } finally {
      setLoading(false);
    }
  };

  const handleUnlock = async (id) => {
    if (!window.confirm('Are you sure you want to unlock this account?')) return;
    try {
      await api.put(`/admin/security/locked-accounts/${id}/unlock`);
      toast.success('Account unlocked successfully');
      fetchData();
    } catch (error) {
      toast.error('Failed to unlock account');
    }
  };

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-200';
      case 'high': return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'low': return 'bg-blue-100 text-blue-800 border-blue-200';
      default: return 'bg-[#2A2A2D] text-white/90 border-white/10';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-white">Security Monitoring</h1>
          <p className="mt-1 text-sm text-white/60">
            Monitor suspicious activities and manage locked accounts
          </p>
        </div>
        <button
          onClick={fetchData}
          className="flex items-center px-4 py-2 bg-[#141416] border border-white/5 border border-white/20 rounded-md shadow-sm text-sm font-medium text-white/80 hover:bg-[#1C1C1F]"
        >
          <RefreshCw size={16} className={`mr-2 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      <div className="bg-[#141416] border border-white/5 rounded-lg shadow">
        <div className="border-b border-white/10">
          <nav className="flex -mb-px px-6" aria-label="Tabs">
            <button
              onClick={() => setActiveTab('alerts')}
              className={`${
                activeTab === 'alerts'
                  ? 'border-[#6C2BD9] text-[#6C2BD9]'
                  : 'border-transparent text-white/60 hover:text-white/80 hover:border-white/20'
              } flex items-center whitespace-nowrap py-4 px-4 border-b-2 font-medium text-sm`}
            >
              <AlertTriangle size={16} className="mr-2" />
              Security Alerts
            </button>
            <button
              onClick={() => setActiveTab('locked-accounts')}
              className={`${
                activeTab === 'locked-accounts'
                  ? 'border-[#6C2BD9] text-[#6C2BD9]'
                  : 'border-transparent text-white/60 hover:text-white/80 hover:border-white/20'
              } flex items-center whitespace-nowrap py-4 px-4 border-b-2 font-medium text-sm ml-8`}
            >
              <Lock size={16} className="mr-2" />
              Locked Accounts
            </button>
            <button
              onClick={() => setActiveTab('api-abuse-logs')}
              className={`${
                activeTab === 'api-abuse-logs'
                  ? 'border-[#6C2BD9] text-[#6C2BD9]'
                  : 'border-transparent text-white/60 hover:text-white/80 hover:border-white/20'
              } flex items-center whitespace-nowrap py-4 px-4 border-b-2 font-medium text-sm ml-8`}
            >
              <Activity size={16} className="mr-2" />
              API Abuse Logs
            </button>
          </nav>
        </div>

        <div className="p-6">
          {loading ? (
            <div className="animate-pulse">
              <div className="h-10 bg-[#1C1C1F] rounded-t-lg mb-2"></div>
              {[...Array(5)].map((_, i) => (
                <div key={i} className="flex space-x-4 px-6 py-5 border-b border-white/5">
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                  <div className="h-4 bg-white/5 rounded w-1/5"></div>
                </div>
              ))}
            </div>
          ) : activeTab === 'alerts' ? (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-white/10">
                <thead className="bg-[#1C1C1F]">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Date & Time</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">User</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Type & Severity</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Details</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Client Info</th>
                  </tr>
                </thead>
                <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                  {alerts?.map((alert) => (
                    <tr key={alert.id}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                        {new Date(alert.created_at).toLocaleString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">{alert.user?.name || 'Unknown'}</div>
                        <div className="text-sm text-white/60">{alert.user?.email || alert.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-white mb-1">{alert.type.replace(/_/g, ' ').toUpperCase()}</div>
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full border ${getSeverityColor(alert.severity)}`}>
                          {alert.severity.toUpperCase()}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm font-medium text-white">{alert.title}</div>
                        <div className="text-sm text-white/60 truncate max-w-xs">{alert.message}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                        <div className="flex items-center mb-1">
                          <Globe size={14} className="mr-1" />
                          {alert.ip_address || 'N/A'}
                        </div>
                        <div className="flex items-center text-xs truncate max-w-[150px]" title={alert.user_agent}>
                          <MonitorSmartphone size={14} className="mr-1" />
                          {alert.user_agent?.split(' ')[0] || 'N/A'}
                        </div>
                      </td>
                    </tr>
                  ))}
                  {(!alerts || alerts.length === 0) && (
                    <tr>
                      <td colSpan="5" className="px-6 py-4 text-center text-sm text-white/60">
                        No security alerts found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          ) : activeTab === 'locked-accounts' ? (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-white/10">
                <thead className="bg-[#1C1C1F]">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">User</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Locked At</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Locked Until</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                  {lockedAccounts?.map((lock) => {
                    const isCurrentlyLocked = !lock.unlocked_at && (!lock.locked_until || new Date(lock.locked_until) > new Date());
                    
                    return (
                      <tr key={lock.id}>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-white">{lock.user?.name || 'Unknown'}</div>
                          <div className="text-sm text-white/60">{lock.user?.email || lock.email}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                          {new Date(lock.created_at).toLocaleString()}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                          {lock.locked_until ? new Date(lock.locked_until).toLocaleString() : 'Permanent'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          {isCurrentlyLocked ? (
                            <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">
                              Locked
                            </span>
                          ) : (
                            <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                              Unlocked
                            </span>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          {isCurrentlyLocked && (
                            <button
                              onClick={() => handleUnlock(lock.id)}
                              className="text-indigo-600 hover:text-indigo-900 flex items-center"
                            >
                              <Unlock size={16} className="mr-1" />
                              Unlock
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                  {(!lockedAccounts || lockedAccounts.length === 0) && (
                    <tr>
                      <td colSpan="5" className="px-6 py-4 text-center text-sm text-white/60">
                        No locked accounts found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          ) : (
            <div>
              <div className="flex gap-4 mb-4 px-6 pt-4">
                <input 
                  type="text" 
                  placeholder="Filter IP..." 
                  className="border border-white/20 rounded px-3 py-1.5 text-sm"
                  onChange={(e) => {
                    // Simple client-side filter for now, or debounce and fetch
                    // For brevity, we could just rely on backend filter by triggering fetch with params
                  }}
                  id="filter-ip"
                />
                <input 
                  type="text" 
                  placeholder="Limiter..." 
                  className="border border-white/20 rounded px-3 py-1.5 text-sm"
                  id="filter-limiter"
                />
                <button 
                  onClick={() => {
                    const ip = document.getElementById('filter-ip').value;
                    const limiter = document.getElementById('filter-limiter').value;
                    api.get('/admin/security/api-abuse-logs', { params: { ip_address: ip, limiter: limiter } })
                      .then(res => setAbuseLogs(res.data.data.data || res.data.data || res.data))
                      .catch(() => toast.error('Failed to filter'));
                  }}
                  className="bg-[#6C2BD9] text-white px-3 py-1.5 rounded text-sm hover:bg-[#5b24b8]"
                >
                  Apply Filters
                </button>
              </div>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-white/10">
                <thead className="bg-[#1C1C1F]">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Time</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Limiter</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Endpoint & Method</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">IP / Client Info</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">User ID</th>
                  </tr>
                </thead>
                <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                  {abuseLogs?.map((log) => (
                    <tr key={log.id}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                        {new Date(log.created_at).toLocaleString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-purple-100 text-purple-800">
                          {log.limiter}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">{log.endpoint}</div>
                        <div className="text-sm text-white/60">{log.method}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                        <div className="flex items-center mb-1">
                          <Globe size={14} className="mr-1" />
                          {log.ip_address || 'N/A'}
                        </div>
                        <div className="flex items-center text-xs truncate max-w-[150px]" title={log.user_agent}>
                          <MonitorSmartphone size={14} className="mr-1" />
                          {log.user_agent?.split(' ')[0] || 'N/A'}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                        {log.user_id ? `User #${log.user_id}` : 'Guest'}
                      </td>
                    </tr>
                  ))}
                  {(!abuseLogs || abuseLogs.length === 0) && (
                    <tr>
                      <td colSpan="5" className="px-6 py-4 text-center text-sm text-white/60">
                        No API abuse logs found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default SecurityDashboard;
