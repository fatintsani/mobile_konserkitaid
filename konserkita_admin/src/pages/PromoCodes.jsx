import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, RefreshCcw } from 'lucide-react';

const PromoCodes = () => {
  const [promos, setPromos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({});
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  
  const [formData, setFormData] = useState({
    code: '',
    description: '',
    discount_type: 'percentage',
    discount_value: '',
    max_discount: '',
    quota: '',
    start_date: '',
    end_date: '',
    status: 'active'
  });

  const fetchPromos = async (pageUrl = null) => {
    setLoading(true);
    try {
      const url = pageUrl || `/admin/promos?page=1`;
      const response = await api.get(url);
      if (response.data.success) {
        setPromos(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch promos', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPromos();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleCreate = () => {
    setEditingId(null);
    setFormData({
      code: '', description: '', discount_type: 'percentage', 
      discount_value: '', max_discount: '', quota: '', 
      start_date: '', end_date: '', status: 'active'
    });
    setShowModal(true);
  };

  const handleEdit = (promo) => {
    setEditingId(promo.id);
    setFormData({
      code: promo.code,
      description: promo.description || '',
      discount_type: promo.discount_type,
      discount_value: promo.discount_value,
      max_discount: promo.max_discount || '',
      quota: promo.quota,
      start_date: promo.start_date ? promo.start_date.split(' ')[0] : '',
      end_date: promo.end_date ? promo.end_date.split(' ')[0] : '',
      status: promo.status
    });
    setShowModal(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this promo code?')) return;
    try {
      const response = await api.delete(`/admin/promos/${id}`);
      if (response.data.success) fetchPromos();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to delete promo');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      let payload = { ...formData };
      if (!payload.start_date) delete payload.start_date;
      if (!payload.end_date) delete payload.end_date;
      if (!payload.max_discount) delete payload.max_discount;

      if (editingId) {
        await api.put(`/admin/promos/${editingId}`, payload);
      } else {
        await api.post(`/admin/promos`, payload);
      }
      setShowModal(false);
      fetchPromos();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to save promo code');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white/90">Promo Code Management</h1>
        <div className="flex space-x-2">
          <button onClick={() => fetchPromos()} className="p-2 text-white/60 hover:text-[#6C2BD9] bg-[#141416] border border-white/5 rounded-full shadow-sm">
            <RefreshCcw size={20} />
          </button>
          <button onClick={handleCreate} className="flex items-center px-4 py-2 bg-[#6C2BD9] text-white rounded-lg hover:bg-[#5b24b8] shadow-sm">
            <Plus size={18} className="mr-2" /> Add Promo Code
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase">Code</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase">Discount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase">Usage / Quota</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase">Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-white/60 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                {promos.length === 0 ? (
                  <tr><td colSpan="5" className="px-6 py-8 text-center text-white/60">No promo codes found.</td></tr>
                ) : (
                  promos.map((promo) => (
                    <tr key={promo.id} className="hover:bg-[#1C1C1F]">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-bold text-[#6C2BD9] uppercase">{promo.code}</div>
                        <div className="text-xs text-white/60">{promo.description || '-'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-white">
                          {promo.discount_type === 'percentage' ? `${promo.discount_value}%` : `Rp ${parseInt(promo.discount_value).toLocaleString('id-ID')}`}
                        </div>
                        {promo.max_discount && <div className="text-xs text-white/60">Max Rp {parseInt(promo.max_discount).toLocaleString('id-ID')}</div>}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-white">{promo.used} / {promo.quota}</div>
                        <div className="w-24 bg-gray-200 rounded-full h-1.5 mt-1">
                          <div className="bg-[#FF4D8D] h-1.5 rounded-full" style={{ width: `${Math.min((promo.used / promo.quota) * 100, 100)}%` }}></div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          promo.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-[#2A2A2D] text-white/90'
                        }`}>
                          {promo.status}
                        </span>
                        {promo.end_date && new Date(promo.end_date) < new Date() && (
                          <span className="ml-2 px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">
                            expired
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          <button onClick={() => handleEdit(promo)} className="text-blue-600 hover:text-blue-900 bg-blue-500/10 p-1.5 rounded-md">
                            <Edit2 size={18} />
                          </button>
                          <button 
                            onClick={() => {
                              if (promo.used > 0) {
                                alert('Cannot delete promo code that has been used.');
                              } else {
                                handleDelete(promo.id);
                              }
                            }} 
                            className={`p-1.5 rounded-md ${promo.used > 0 ? 'text-white/50 bg-[#1C1C1F] cursor-not-allowed' : 'text-red-600 hover:text-red-900 bg-red-500/10'}`}
                            title={promo.used > 0 ? 'Cannot delete used promo' : 'Delete'}
                          >
                            <Trash2 size={18} />
                          </button>
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

      {/* Pagination */}
      {!loading && pagination.total > 0 && (
        <div className="flex items-center justify-between bg-[#141416] border border-white/5 px-4 py-3 border border-white/5 rounded-xl shadow-sm sm:px-6">
          <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p className="text-sm text-white/80">
                Showing <span className="font-medium">{pagination.from}</span> to <span className="font-medium">{pagination.to}</span> of <span className="font-medium">{pagination.total}</span> results
              </p>
            </div>
            <div>
              <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                <button
                  onClick={() => fetchPromos(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-white/20 bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchPromos(pagination.next_page_url)}
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

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:p-0">
            <div className="fixed inset-0 transition-opacity bg-[#1C1C1F]0 bg-opacity-75" onClick={() => setShowModal(false)} />
            <div className="relative inline-block w-full max-w-md p-6 overflow-hidden text-left align-middle transition-all transform bg-[#141416] border border-white/5 shadow-xl rounded-2xl">
              <h3 className="text-lg font-medium leading-6 text-white mb-4">
                {editingId ? 'Edit Promo Code' : 'Add Promo Code'}
              </h3>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-white/80">Code</label>
                  <input type="text" name="code" required value={formData.code} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border uppercase" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-white/80">Description</label>
                  <input type="text" name="description" value={formData.description} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-white/80">Discount Type</label>
                    <select name="discount_type" value={formData.discount_type} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border">
                      <option value="percentage">Percentage (%)</option>
                      <option value="fixed">Fixed Amount (Rp)</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-white/80">Value</label>
                    <input type="number" name="discount_value" required value={formData.discount_value} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-white/80">Max Discount (Rp)</label>
                    <input type="number" name="max_discount" value={formData.max_discount} onChange={handleInputChange} disabled={formData.discount_type === 'fixed'} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border disabled:bg-[#2A2A2D]" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-white/80">Quota</label>
                    <input type="number" name="quota" required value={formData.quota} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-white/80">Start Date</label>
                    <input type="date" name="start_date" value={formData.start_date} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-white/80">End Date</label>
                    <input type="date" name="end_date" value={formData.end_date} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-white/80">Status</label>
                  <select name="status" value={formData.status} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border">
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
                <div className="mt-6 flex justify-end space-x-3">
                  <button type="button" onClick={() => setShowModal(false)} className="px-4 py-2 text-sm font-medium text-white/80 bg-[#141416] border border-white/5 border border-white/20 rounded-md hover:bg-[#1C1C1F]">
                    Cancel
                  </button>
                  <button type="submit" className="px-4 py-2 text-sm font-medium text-white bg-[#6C2BD9] border border-transparent rounded-md hover:bg-[#5b24b8]">
                    Save
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PromoCodes;
