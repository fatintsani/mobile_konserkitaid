import { useState, useEffect } from 'react';
import axios from 'axios';
import DataTable from 'react-data-table-component';
import { RefreshCcw, Check, X, CreditCard, Search, X as XIcon } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { format } from 'date-fns';

const API_URL = import.meta.env.VITE_API_URL;

const Payouts = () => {
  const [payouts, setPayouts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterText, setFilterText] = useState('');
  const [selectedPayout, setSelectedPayout] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalAction, setModalAction] = useState(null); // 'approve', 'reject', 'paid'
  const [adminNote, setAdminNote] = useState('');

  const fetchPayouts = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_URL}/admin/payouts`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setPayouts(response.data.data);
    } catch (error) {
      toast.error('Failed to fetch payouts');
      console.error('Error fetching payouts:', error);
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
      const token = localStorage.getItem('token');
      const endpoint = `${API_URL}/admin/payouts/${selectedPayout.id}/${modalAction === 'paid' ? 'mark-paid' : modalAction}`;
      
      const payload = {};
      if (modalAction === 'reject' || modalAction === 'paid') {
        payload.admin_note = adminNote;
      }

      await axios.put(endpoint, payload, {
        headers: { Authorization: `Bearer ${token}` }
      });

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

  const columns = [
    {
      name: 'ID',
      selector: row => row.id,
      sortable: true,
      width: '80px',
    },
    {
      name: 'Organizer',
      selector: row => row.organizer?.user?.name || 'Unknown',
      sortable: true,
    },
    {
      name: 'Amount',
      selector: row => row.amount,
      sortable: true,
      format: row => `Rp ${new Intl.NumberFormat('id-ID').format(row.amount)}`,
    },
    {
      name: 'Bank Info',
      selector: row => `${row.bank_name} - ${row.bank_account_number}`,
      sortable: false,
    },
    {
      name: 'Status',
      selector: row => row.status,
      sortable: true,
      cell: row => {
        let bgColor = 'bg-gray-100';
        let textColor = 'text-gray-800';
        if (row.status === 'paid') {
          bgColor = 'bg-green-100'; textColor = 'text-green-800';
        } else if (row.status === 'approved') {
          bgColor = 'bg-blue-100'; textColor = 'text-blue-800';
        } else if (row.status === 'rejected') {
          bgColor = 'bg-red-100'; textColor = 'text-red-800';
        } else {
          bgColor = 'bg-orange-100'; textColor = 'text-orange-800';
        }
        return (
          <span className={`px-2 py-1 rounded-full text-xs font-semibold ${bgColor} ${textColor}`}>
            {row.status.toUpperCase()}
          </span>
        );
      }
    },
    {
      name: 'Date',
      selector: row => row.requested_at,
      sortable: true,
      format: row => format(new Date(row.requested_at), 'dd MMM yyyy, HH:mm'),
    },
    {
      name: 'Actions',
      cell: row => (
        <div className="flex space-x-2">
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
              className="p-1 bg-green-100 text-green-600 rounded hover:bg-green-200 flex items-center gap-1"
              title="Mark Paid"
            >
              <CreditCard size={16} /> Paid
            </button>
          )}
        </div>
      ),
    },
  ];

  const filteredItems = payouts.filter(item => {
    return (item.organizer?.user?.name && item.organizer.user.name.toLowerCase().includes(filterText.toLowerCase())) ||
           item.status.toLowerCase().includes(filterText.toLowerCase()) ||
           item.bank_name.toLowerCase().includes(filterText.toLowerCase());
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
              className="pl-10 w-full p-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none transition-all"
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

        <DataTable
          columns={columns}
          data={filteredItems}
          pagination
          progressPending={loading}
          customStyles={{
            headRow: {
              style: {
                backgroundColor: '#f8fafc',
                borderBottomColor: '#e2e8f0',
              },
            },
            headCells: {
              style: {
                fontSize: '0.875rem',
                fontWeight: '600',
                color: '#475569',
              },
            },
            cells: {
              style: {
                fontSize: '0.875rem',
                color: '#334155',
              },
            },
          }}
        />
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
