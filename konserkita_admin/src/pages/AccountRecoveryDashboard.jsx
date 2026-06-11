import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { RefreshCw, CheckCircle, XCircle } from 'lucide-react';
import toast from 'react-hot-toast';

const AccountRecoveryDashboard = () => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(false);
  const [adminNote, setAdminNote] = useState('');
  const [selectedRequestId, setSelectedRequestId] = useState(null);

  useEffect(() => {
    fetchRequests();
  }, []);

  const fetchRequests = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/account-recovery/requests');
      setRequests(response.data.data.data || response.data.data || response.data);
    } catch (error) {
      toast.error('Failed to fetch account recovery requests');
    } finally {
      setLoading(false);
    }
  };

  const handleDecision = async (id, status) => {
    if (!adminNote && status === 'rejected') {
      toast.error('Please provide a reason for rejection in the admin note.');
      return;
    }

    try {
      await api.put(`/admin/account-recovery/requests/${id}/decision`, {
        status,
        admin_note: adminNote
      });
      toast.success(`Request ${status} successfully`);
      setSelectedRequestId(null);
      setAdminNote('');
      fetchRequests();
    } catch (error) {
      toast.error(`Failed to ${status} request`);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-white">Account Recovery Requests</h1>
          <p className="mt-1 text-sm text-white/60">
            Manage manual account and 2FA recovery requests
          </p>
        </div>
        <button
          onClick={fetchRequests}
          className="flex items-center px-4 py-2 bg-[#141416] border border-white/5 border border-white/20 rounded-md shadow-sm text-sm font-medium text-white/80 hover:bg-[#1C1C1F]"
        >
          <RefreshCw size={16} className={`mr-2 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      <div className="bg-[#141416] border border-white/5 rounded-lg shadow overflow-hidden">
        <div className="p-6">
          {loading ? (
            <div className="flex justify-center items-center h-64">
              <RefreshCw size={32} className="animate-spin text-white/50" />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-white/10">
                <thead className="bg-[#1C1C1F]">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Date</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">User / Email</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Type</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                  {requests?.map((req) => (
                    <tr key={req.id}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                        {new Date(req.created_at).toLocaleString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">{req.user?.name || 'Unknown User'}</div>
                        <div className="text-sm text-white/60">{req.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-white">
                        {req.type.replace(/_/g, ' ').toUpperCase()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          req.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                          req.status === 'approved' ? 'bg-green-100 text-green-800' :
                          req.status === 'completed' ? 'bg-blue-100 text-blue-800' :
                          'bg-red-100 text-red-800'
                        }`}>
                          {req.status.toUpperCase()}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm font-medium">
                        {req.status === 'pending' && (
                          <div className="flex flex-col space-y-2">
                            {selectedRequestId === req.id ? (
                              <div className="flex flex-col space-y-2 w-64">
                                <textarea
                                  className="border rounded p-2 text-sm w-full"
                                  placeholder="Admin note (required for rejection)"
                                  value={adminNote}
                                  onChange={(e) => setAdminNote(e.target.value)}
                                  rows={2}
                                />
                                <div className="flex space-x-2">
                                  <button
                                    onClick={() => handleDecision(req.id, 'approved')}
                                    className="flex items-center justify-center flex-1 bg-green-100 text-green-700 px-3 py-1 rounded hover:bg-green-200"
                                  >
                                    <CheckCircle size={16} className="mr-1" /> Approve
                                  </button>
                                  <button
                                    onClick={() => handleDecision(req.id, 'rejected')}
                                    className="flex items-center justify-center flex-1 bg-red-100 text-red-700 px-3 py-1 rounded hover:bg-red-200"
                                  >
                                    <XCircle size={16} className="mr-1" /> Reject
                                  </button>
                                </div>
                                <button
                                  onClick={() => { setSelectedRequestId(null); setAdminNote(''); }}
                                  className="text-white/60 text-xs text-center"
                                >
                                  Cancel
                                </button>
                              </div>
                            ) : (
                              <button
                                onClick={() => setSelectedRequestId(req.id)}
                                className="text-indigo-600 hover:text-indigo-900"
                              >
                                Review Request
                              </button>
                            )}
                          </div>
                        )}
                        {req.status !== 'pending' && req.admin_note && (
                          <div className="text-xs text-white/60 max-w-xs truncate" title={req.admin_note}>
                            Note: {req.admin_note}
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
                  {(!requests || requests.length === 0) && (
                    <tr>
                      <td colSpan="5" className="px-6 py-4 text-center text-sm text-white/60">
                        No recovery requests found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AccountRecoveryDashboard;
