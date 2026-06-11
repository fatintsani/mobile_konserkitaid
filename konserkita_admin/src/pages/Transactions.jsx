import { useState, useEffect } from 'react';
import api from '../api/axios';
import { RefreshCcw } from 'lucide-react';

const Transactions = () => {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [selectedTransaction, setSelectedTransaction] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const [pagination, setPagination] = useState({});

  const fetchTransactions = async (pageUrl = null) => {
    setLoading(true);
    try {
      let url = pageUrl || `/admin/transactions?page=1`;
      if (statusFilter && !pageUrl) url += `&payment_status=${statusFilter}`;
      
      const response = await api.get(url);
      if (response.data.success) {
        setTransactions(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch transactions', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTransactions(`/admin/transactions?page=1${statusFilter ? `&payment_status=${statusFilter}` : ''}`);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount);
  };

  const handleViewDetails = async (id) => {
    try {
      const response = await api.get(`/admin/transactions/${id}`);
      if (response.data.success) {
        setSelectedTransaction(response.data.data);
        setShowModal(true);
      }
    } catch (error) {
      console.error(error);
      alert('Failed to load transaction details.');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white/90">Transactions</h1>
        <div className="flex items-center space-x-4">
          <select 
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border"
          >
            <option value="">All Statuses</option>
            <option value="success">Success</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
          </select>
          <button onClick={fetchTransactions} className="p-2 text-white/60 hover:text-[#6C2BD9] bg-[#141416] border border-white/5 rounded-full shadow-sm">
            <RefreshCcw size={20} />
          </button>
        </div>
      </div>

      <div className="bg-[#141416] border border-white/5 rounded-xl shadow-sm border border-white/5 overflow-hidden">
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
          ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-white/10">
              <thead className="bg-[#1C1C1F]">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Order ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">User</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Event Details</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Total Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-white/60 uppercase tracking-wider">Date</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-white/60 uppercase tracking-wider">Action</th>
                </tr>
              </thead>
              <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                {transactions.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-8 text-center text-white/60">No transactions found.</td>
                  </tr>
                ) : (
                  transactions.map((trx) => (
                    <tr key={trx.id} className="hover:bg-[#1C1C1F]">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">{trx.invoice_number || `INV-${trx.id}`}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-white">{trx.user?.name || 'Unknown'}</div>
                        <div className="text-xs text-white/60">{trx.user?.email}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-white line-clamp-1">
                          {trx.items && trx.items.length > 0 
                            ? trx.items[0]?.ticket_type?.event?.title || 'Unknown Event'
                            : 'N/A'}
                        </div>
                        <div className="text-xs text-white/60">
                          {trx.items && trx.items.length > 0 ? `${trx.items.length} ticket(s)` : ''}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">{formatCurrency(trx.total_amount)}</div>
                        <div className="text-xs text-white/60">{trx.payment_type || '-'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          trx.payment_status === 'success' ? 'bg-green-100 text-green-800' : 
                          trx.payment_status === 'pending' ? 'bg-yellow-100 text-yellow-800' : 'bg-red-100 text-red-800'
                        }`}>
                          {trx.payment_status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-white/60">
                        {new Date(trx.created_at).toLocaleString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button onClick={() => handleViewDetails(trx.id)} className="text-[#6C2BD9] hover:text-[#5b24b8] bg-[#6C2BD9] bg-opacity-10 p-1.5 rounded-md text-xs font-bold px-3">
                          Detail
                        </button>
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
                  onClick={() => fetchTransactions(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-white/20 bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchTransactions(pagination.next_page_url)}
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

      {/* Detail Modal */}
      {showModal && selectedTransaction && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:p-0">
            <div className="fixed inset-0 transition-opacity bg-[#1C1C1F]0 bg-opacity-75" onClick={() => setShowModal(false)} />
            <div className="relative inline-block w-full max-w-2xl p-6 overflow-hidden text-left align-middle transition-all transform bg-[#141416] border border-white/5 shadow-xl rounded-2xl">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-bold text-white">Transaction Details</h3>
                <button onClick={() => setShowModal(false)} className="text-white/50 hover:text-white/60">✕</button>
              </div>
              
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4 bg-[#1C1C1F] p-4 rounded-lg">
                  <div>
                    <div className="text-sm text-white/60">Invoice Number</div>
                    <div className="font-semibold">{selectedTransaction.invoice_number || `INV-${selectedTransaction.id}`}</div>
                  </div>
                  <div>
                    <div className="text-sm text-white/60">Status</div>
                    <div className="font-semibold uppercase">{selectedTransaction.payment_status}</div>
                  </div>
                  <div>
                    <div className="text-sm text-white/60">Customer Name</div>
                    <div className="font-semibold">{selectedTransaction.user?.name}</div>
                  </div>
                  <div>
                    <div className="text-sm text-white/60">Total Amount</div>
                    <div className="font-semibold text-[#6C2BD9]">{formatCurrency(selectedTransaction.total_amount)}</div>
                  </div>
                </div>

                <div className="border-t pt-4">
                  <h4 className="font-bold mb-2">Midtrans Info</h4>
                  <div className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
                    <div className="text-white/60">Snap Token</div>
                    <div className="font-mono break-all">{selectedTransaction.snap_token || '-'}</div>
                    
                    <div className="text-white/60">Payment Type</div>
                    <div>{selectedTransaction.payment?.payment_type || '-'}</div>
                    
                    <div className="text-white/60">Gateway Transaction ID</div>
                    <div className="font-mono">{selectedTransaction.payment?.gateway_transaction_id || '-'}</div>
                    
                    <div className="text-white/60">Raw Status</div>
                    <div>{selectedTransaction.payment?.transaction_status || '-'}</div>
                    
                    <div className="text-white/60">Transaction Time (Paid At)</div>
                    <div>{selectedTransaction.payment?.transaction_time ? new Date(selectedTransaction.payment.transaction_time).toLocaleString() : '-'}</div>
                  </div>
                </div>
              </div>

              <div className="mt-6 flex justify-end">
                <button onClick={() => setShowModal(false)} className="px-4 py-2 text-sm font-medium text-white/80 bg-[#141416] border border-white/5 border border-white/20 rounded-md hover:bg-[#1C1C1F]">
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Transactions;
