import { useState, useEffect } from 'react';
import api from '../api/axios';
import { RefreshCcw, CheckCircle, XCircle, DollarSign, Eye } from 'lucide-react';

const Refunds = () => {
  const [refunds, setRefunds] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [pagination, setPagination] = useState({});
  const [selectedRefund, setSelectedRefund] = useState(null);
  const [rejectNote, setRejectNote] = useState('');
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);

  const fetchRefunds = async (pageUrl = null) => {
    setLoading(true);
    try {
      let url = pageUrl || `/admin/refunds?page=1`;
      if (statusFilter && !pageUrl) url += `&status=${statusFilter}`;
      
      const response = await api.get(url);
      if (response.data.success) {
        setRefunds(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch refunds', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRefunds(`/admin/refunds?page=1${statusFilter ? `&status=${statusFilter}` : ''}`);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  const handleApprove = async (id) => {
    if (!window.confirm('Are you sure you want to approve this refund?')) return;
    try {
      const response = await api.put(`/admin/refunds/${id}/approve`);
      if (response.data.success) fetchRefunds();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to approve refund');
    }
  };

  const handleReject = async () => {
    if (!rejectNote.trim()) {
      alert('Admin note is required to reject.');
      return;
    }
    try {
      const response = await api.put(`/admin/refunds/${selectedRefund.id}/reject`, { admin_note: rejectNote });
      if (response.data.success) {
        setShowRejectModal(false);
        setRejectNote('');
        fetchRefunds();
      }
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to reject refund');
    }
  };

  const handleProcess = async (id) => {
    if (!window.confirm('Are you sure you want to mark this refund as processed? This will cancel the tickets.')) return;
    try {
      const response = await api.put(`/admin/refunds/${id}/process`);
      if (response.data.success) fetchRefunds();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to process refund');
    }
  };

  const openRejectModal = (refund) => {
    setSelectedRefund(refund);
    setRejectNote('');
    setShowRejectModal(true);
  };

  const openDetailModal = async (refund) => {
    try {
      const response = await api.get(`/admin/refunds/${refund.id}`);
      if (response.data.success) {
        setSelectedRefund(response.data.data);
        setShowDetailModal(true);
      }
    } catch (error) {
      alert('Failed to fetch details');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white/90">Refunds Management</h1>
        <div className="flex items-center space-x-4">
          <select 
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border"
          >
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
            <option value="processed">Processed</option>
          </select>
          <button onClick={fetchRefunds} className="p-2 text-white/60 hover:text-[#6C2BD9] bg-[#141416] border border-white/5 rounded-full shadow-sm">
            <RefreshCcw size={20} />
          </button>
        </div>
      </div>

      <div className="bg-[#141416] border border-white/5 rounded-xl shadow-sm border border-white/5 overflow-hidden">
        {loading ? (
          <div className="p-8 flex justify-center"><RefreshCcw className="animate-spin text-[#6C2BD9]" size={32} /></div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-white/10">
              <thead className="bg-[#1C1C1F]">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Transaction</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">User</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-white/60 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                {refunds.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-8 text-center text-white/60">No refunds found.</td>
                  </tr>
                ) : (
                  refunds.map((refund) => (
                    <tr key={refund.id} className="hover:bg-[#1C1C1F]">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">#{refund.transaction_id}</div>
                        <div className="text-xs text-white/60">{new Date(refund.requested_at).toLocaleDateString()}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-white">{refund.user?.name}</div>
                        <div className="text-xs text-white/60">{refund.user?.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-green-600">Rp {Number(refund.refund_amount).toLocaleString()}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          refund.status === 'processed' ? 'bg-green-100 text-green-800' : 
                          refund.status === 'approved' ? 'bg-blue-100 text-blue-800' : 
                          refund.status === 'pending' ? 'bg-orange-100 text-orange-800' : 'bg-red-100 text-red-800'
                        }`}>
                          {refund.status.toUpperCase()}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          <button onClick={() => openDetailModal(refund)} className="text-white/70 hover:text-white bg-[#1C1C1F] p-1.5 rounded-md" title="View Detail">
                            <Eye size={18} />
                          </button>
                          {refund.status === 'pending' && (
                            <>
                              <button onClick={() => handleApprove(refund.id)} className="text-blue-600 hover:text-blue-900 bg-blue-500/10 p-1.5 rounded-md" title="Approve">
                                <CheckCircle size={18} />
                              </button>
                              <button onClick={() => openRejectModal(refund)} className="text-red-600 hover:text-red-900 bg-red-500/10 p-1.5 rounded-md" title="Reject">
                                <XCircle size={18} />
                              </button>
                            </>
                          )}
                          {refund.status === 'approved' && (
                            <button onClick={() => handleProcess(refund.id)} className="text-green-600 hover:text-green-900 bg-green-500/10 p-1.5 rounded-md" title="Mark as Processed">
                              <DollarSign size={18} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Pagination Controls */}
      {!loading && pagination.total > 0 && (
        <div className="flex items-center justify-between bg-[#141416] border border-white/5 px-4 py-3 border border-white/5 rounded-xl shadow-sm sm:px-6">
          <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p className="text-sm text-white/80">
                Showing <span className="font-medium">{pagination.from}</span> to <span className="font-medium">{pagination.to}</span> of{' '}
                <span className="font-medium">{pagination.total}</span> results
              </p>
            </div>
            <div>
              <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                <button
                  onClick={() => fetchRefunds(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-white/20 bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchRefunds(pagination.next_page_url)}
                  disabled={!pagination.next_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-white/20 bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-50"
                >
                  Next
                </button>
              </nav>
            </div>
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {showRejectModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-[#141416] border border-white/5 rounded-xl p-6 w-full max-w-md">
            <h2 className="text-xl font-bold mb-4">Reject Refund Request</h2>
            <p className="text-sm text-white/70 mb-4">Please provide a reason for rejecting this refund request.</p>
            <textarea
              className="w-full border-white/20 rounded-md p-2 border focus:ring-[#6C2BD9] focus:border-[#6C2BD9]"
              rows="4"
              value={rejectNote}
              onChange={(e) => setRejectNote(e.target.value)}
              placeholder="Admin note..."
            ></textarea>
            <div className="flex justify-end space-x-3 mt-6">
              <button 
                onClick={() => setShowRejectModal(false)}
                className="px-4 py-2 border border-white/20 rounded-md text-white/80 hover:bg-[#1C1C1F]"
              >
                Cancel
              </button>
              <button 
                onClick={handleReject}
                className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
              >
                Confirm Reject
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {showDetailModal && selectedRefund && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-[#141416] border border-white/5 rounded-xl p-6 w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold">Refund Details</h2>
              <button onClick={() => setShowDetailModal(false)} className="text-white/60 hover:text-white/90">
                <XCircle size={24} />
              </button>
            </div>
            
            <div className="space-y-4">
              <div>
                <p className="text-sm text-white/60">Transaction ID</p>
                <p className="font-medium">#{selectedRefund.transaction_id}</p>
              </div>
              <div>
                <p className="text-sm text-white/60">User</p>
                <p className="font-medium">{selectedRefund.user?.name} ({selectedRefund.user?.email})</p>
              </div>
              <div>
                <p className="text-sm text-white/60">Refund Amount</p>
                <p className="font-medium text-green-600">Rp {Number(selectedRefund.refund_amount).toLocaleString()}</p>
              </div>
              <div>
                <p className="text-sm text-white/60">Status</p>
                <p className="font-medium uppercase">{selectedRefund.status}</p>
              </div>
              <div>
                <p className="text-sm text-white/60">Customer Reason</p>
                <p className="font-medium bg-[#1C1C1F] p-2 rounded">{selectedRefund.reason}</p>
              </div>
              {selectedRefund.admin_note && (
                <div>
                  <p className="text-sm text-red-500">Admin Note</p>
                  <p className="font-medium bg-red-500/10 p-2 rounded text-red-800">{selectedRefund.admin_note}</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Refunds;
