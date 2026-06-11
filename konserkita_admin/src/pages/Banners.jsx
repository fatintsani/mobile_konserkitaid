import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, RefreshCcw } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const Banners = () => {
  const { t } = useTranslation();
  const [banners, setBanners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({});
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  
  const [formData, setFormData] = useState({
    title: '',
    title_en: '',
    image_file: null,
    image_preview: '',
    link_url: '',
    status: 'active',
    start_date: '',
    end_date: '',
  });

  const fetchBanners = async (pageUrl = null) => {
    setLoading(true);
    try {
      const url = pageUrl || `/admin/banners?page=1`;
      const response = await api.get(url);
      if (response.data.success) {
        setBanners(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch banners', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBanners();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setFormData({ 
        ...formData, 
        image_file: file,
        image_preview: URL.createObjectURL(file) 
      });
    }
  };

  const handleCreate = () => {
    setEditingId(null);
    setFormData({ title: '', title_en: '', image_file: null, image_preview: '', link_url: '', status: 'active', start_date: '', end_date: '' });
    setShowModal(true);
  };

  const handleEdit = (banner) => {
    setEditingId(banner.id);
    setFormData({
      title: banner.title,
      title_en: banner.title_en || '',
      image_file: null,
      image_preview: banner.image_url,
      link_url: banner.link_url || '',
      status: banner.status,
      start_date: banner.start_date ? banner.start_date.split(' ')[0] : '',
      end_date: banner.end_date ? banner.end_date.split(' ')[0] : '',
    });
    setShowModal(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this banner?')) return;
    try {
      const response = await api.delete(`/admin/banners/${id}`);
      if (response.data.success) fetchBanners();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to delete banner');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const data = new FormData();
      data.append('title', formData.title);
      data.append('title_en', formData.title_en);
      data.append('status', formData.status);
      if (formData.link_url) data.append('link_url', formData.link_url);
      if (formData.start_date) data.append('start_date', formData.start_date);
      if (formData.end_date) data.append('end_date', formData.end_date);
      
      if (formData.image_file) {
        data.append('image', formData.image_file);
      } else if (!editingId) {
        alert('Please select an image.');
        return;
      }

      if (editingId) {
        data.append('_method', 'PUT');
        await api.post(`/admin/banners/${editingId}`, data, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
      } else {
        await api.post(`/admin/banners`, data, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
      }
      setShowModal(false);
      fetchBanners();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to save banner');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white/90">Banner Management</h1>
        <div className="flex space-x-2">
          <button onClick={() => fetchBanners()} className="p-2 text-white/60 hover:text-[#6C2BD9] bg-[#141416] border border-white/5 rounded-full shadow-sm">
            <RefreshCcw size={20} />
          </button>
          <button onClick={handleCreate} className="flex items-center px-4 py-2 bg-[#6C2BD9] text-white rounded-lg hover:bg-[#5b24b8] shadow-sm">
            <Plus size={18} className="mr-2" /> Add Banner
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase">Image</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase">Title & Link</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase">Duration</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-white/60 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                {banners.length === 0 ? (
                  <tr><td colSpan="5" className="px-6 py-8 text-center text-white/60">No banners found.</td></tr>
                ) : (
                  banners.map((banner) => (
                    <tr key={banner.id} className="hover:bg-[#1C1C1F]">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <img src={banner.image_url} alt={banner.title} className="h-16 w-32 object-cover rounded-md border border-white/10" />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">{banner.title}</div>
                        <div className="text-xs text-white/60">{banner.link_url || '-'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          banner.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-[#2A2A2D] text-white/90'
                        }`}>
                          {banner.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-xs text-white/60">Start: {banner.start_date || '-'}</div>
                        <div className="text-xs text-white/60">End: {banner.end_date || '-'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          <button onClick={() => handleEdit(banner)} className="text-blue-600 hover:text-blue-900 bg-blue-500/10 p-1.5 rounded-md">
                            <Edit2 size={18} />
                          </button>
                          <button onClick={() => handleDelete(banner.id)} className="text-red-600 hover:text-red-900 bg-red-500/10 p-1.5 rounded-md">
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
                Showing <span className="font-medium">{pagination.from}</span> to <span className="font-medium">{pagination.to}</span> of{' '}
                <span className="font-medium">{pagination.total}</span> results
              </p>
            </div>
            <div>
              <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                <button
                  onClick={() => fetchBanners(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-white/20 bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchBanners(pagination.next_page_url)}
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
                {editingId ? 'Edit Banner' : 'Add Banner'}
              </h3>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-white/80">{t('forms.title_id')}</label>
                  <input type="text" name="title" required value={formData.title} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-white/80">{t('forms.title_en')}</label>
                  <input type="text" name="title_en" value={formData.title_en} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-white/80">Image</label>
                  <input type="file" name="image" accept="image/*" onChange={handleFileChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                  {formData.image_preview && <img src={formData.image_preview} alt="Preview" className="mt-2 h-20 object-cover rounded" />}
                </div>
                <div>
                  <label className="block text-sm font-medium text-white/80">Link URL (Optional)</label>
                  <input type="url" name="link_url" value={formData.link_url} onChange={handleInputChange} className="mt-1 block w-full border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
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

export default Banners;
