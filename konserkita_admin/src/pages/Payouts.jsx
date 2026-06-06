import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { RefreshCcw, Check, X, CreditCard, Search, X as XIcon } from 'lucide-react';
import { toast } from 'react-hot-toast';

const Payouts = () => {
  const [payouts, setPayouts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterText, setFilterText] = useState('');
  const [selectedPayout, setSelectedPayout] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalAction, setModalAction] = useState(null);
  const [adminNote, setAdminNote] = useState('');

  const fetchPayouts = async () => {
    try {
      const response = await api.get('/admin/payouts');
      if (response.data && response.data.data) {
        setPayouts(Array.isArray(response.data.data) ? response.data.data : []);
      } else {
        setPayouts([]);
      }
    } catch (error) {
      toast.error('Failed to fetch payouts');
      console.error('Error fetching payouts:', error);
      setPayouts([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPayouts();
  }, []);

  const handleAction = async () => {
    if ((modalAction === 'reject' || modalAction === 'paid') && !adminNote.trim()) {
      toast.error(`Admin note is required to ${modalAction} a payout`);
      return;
    }

    try {
      const endpoint = `/admin/payouts/${selectedPayout?.id}/${modalAction === 'paid' ? 'mark-paid' : modalAction}`;
      
      const payload = {};
      if (modalAction === 'reject' || modalAction === 'paid') {
        payload.admin_note = adminNote;
      }

      await api.put(endpoint, payload);

      toast.success(`Payout successfully marked as ${modalAction}`);
      setIsModalOpen(false);
      fetchPayouts();
    } catch (error) {
      toast.error(error.response?.data?.message || `Failed to ${modalAction} payout`);
    }
  };

  const openModal = (payout, action) => {
    setSelectedPayout(payout);
    setModalAction(action);
    setAdminNote('');
    setIsModalOpen(true);
  };



  const filteredItems = (Array.isArray(payouts) ? payouts : []).filter(item => {
    if (!item) return false;
    const orgName = item.organizer?.user?.name || '';
    const status = item.status || '';
    const bankName = item.bank_name || '';
    const bankAccount = item.bank_account_number || '';
    
    const search = filterText ? filterText.toLowerCase() : '';
    
    return orgName.toLowerCase().includes(search) ||
           status.toLowerCase().includes(search) ||
           bankName.toLowerCase().includes(search) ||
           bankAccount.toLowerCase().includes(search);
  });

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Payouts</h1>
          <p className="mt-2 text-gray-600">Manage organizer payout requests</p>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
          <div className="relative w-64">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search size={18} className="text-gray-400" />
            </div>
            <input
              type="text"
              placeholder="Search by name, bank, status..."
              value={filterText}
              onChange={e => setFilterText(e.target.value)}
              className="pl-10 w-full p-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-[#6C2BD9] focus:border-[#6C2BD9] outline-none transition-all"
            />
          </div>
          <button
            onClick={fetchPayouts}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
          >
            <RefreshCcw size={16} />
            Refresh
          </button>
        </div>

        {loading ? (
          <div className="p-8 flex justify-center"><RefreshCcw className="animate-spin text-[#6C2BD9]" size={32} /></div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Organizer</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Bank Info</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredItems.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="px-6 py-8 text-center text-gray-500">No payouts found.</td>
                  </tr>
                ) : (
                  filteredItems.map((row) => (
                    <tr key={row.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        #{row.id}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {row.organizer?.user?.name || 'Unknown'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        Rp {new Intl.NumberFormat('id-ID').format(row.amount)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <div>{row.bank_name}</div>
                        <div className="text-xs">{row.bank_account_number}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 rounded-full text-xs font-semibold ${
                          row.status === 'paid' ? 'bg-green-100 text-green-800' :
                          row.status === 'approved' ? 'bg-blue-100 text-blue-800' :
                          row.status === 'rejected' ? 'bg-red-100 text-red-800' :
                          'bg-orange-100 text-orange-800'
                        }`}>
                          {row.status.toUpperCase()}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {row.requested_at ? (() => {
                          try {
                            return new Date(row.requested_at).toLocaleString('id-ID', {
                              day: '2-digit', month: 'short', year: 'numeric',
                              hour: '2-digit', minute: '2-digit'
                            });
                          } catch(e) { return '-'; }
                        })() : '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          {row.status === 'pending' && (
                            <>
                              <button
                                onClick={() => openModal(row, 'approve')}
                                className="p-1 bg-blue-100 text-blue-600 rounded hover:bg-blue-200"
                                title="Approve"
                              >
                                <Check size={16} />
                              </button>
                              <button
                                onClick={() => openModal(row, 'reject')}
                                className="p-1 bg-red-100 text-red-600 rounded hover:bg-red-200"
                                title="Reject"
                              >
                                <X size={16} />
                              </button>
                            </>
                          )}
                          {row.status === 'approved' && (
                            <button
                              onClick={() => openModal(row, 'paid')}
                              className="px-2 py-1 bg-green-100 text-green-600 rounded hover:bg-green-200 flex items-center gap-1"
                              title="Mark Paid"
                            >
                              <CreditCard size={14} /> Paid
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

      {/* Action Modal */}
      {isModalOpen && selectedPayout && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden animate-slide-up">
            <div className="flex justify-between items-center p-6 border-b border-gray-100">
              <h3 className="text-xl font-bold text-gray-900 capitalize">
                {modalAction === 'paid' ? 'Mark as Paid' : `${modalAction} Payout`}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <XIcon size={24} />
              </button>
            </div>
            
            <div className="p-6 space-y-4">
              <div className="bg-gray-50 rounded-lg p-4 space-y-2">
                <div className="flex justify-between">
                  <span className="text-gray-500">Organizer:</span>
                  <span className="font-medium">{selectedPayout.organizer?.user?.name}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Amount:</span>
                  <span className="font-bold text-blue-600">
                    Rp {new Intl.NumberFormat('id-ID').format(selectedPayout.amount)}
                  </span>
                </div>
                <div className="flex flex-col pt-2 border-t border-gray-200 mt-2">
                  <span className="text-gray-500 text-sm">Transfer to:</span>
                  <span className="font-medium">{selectedPayout.bank_name}</span>
                  <span className="font-medium">{selectedPayout.bank_account_number}</span>
                  <span className="text-sm text-gray-600">a/n {selectedPayout.bank_account_name}</span>
                </div>
              </div>

              {(modalAction === 'reject' || modalAction === 'paid') && (
                <div className="space-y-2">
                  <label className="block text-sm font-medium text-gray-700">
                    {modalAction === 'paid' ? 'Payment Reference / Note' : 'Reason for Rejection'} <span className="text-red-500">*</span>
                  </label>
                  <textarea
                    className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-shadow"
                    rows="3"
                    placeholder={modalAction === 'paid' ? 'e.g. TRF-123456789 via BCA' : 'e.g. Invalid bank account details'}
                    value={adminNote}
                    onChange={(e) => setAdminNote(e.target.value)}
                  ></textarea>
                </div>
              )}
            </div>

            <div className="flex justify-end gap-3 p-6 border-t border-gray-100 bg-gray-50">
              <button
                onClick={() => setIsModalOpen(false)}
                className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 font-medium transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleAction}
                className={`px-4 py-2 text-white rounded-lg font-medium transition-colors ${
                  modalAction === 'approve' ? 'bg-blue-600 hover:bg-blue-700' :
                  modalAction === 'reject' ? 'bg-red-600 hover:bg-red-700' :
                  'bg-green-600 hover:bg-green-700'
                }`}
              >
                Confirm {modalAction === 'paid' ? 'Paid' : modalAction}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Payouts;
