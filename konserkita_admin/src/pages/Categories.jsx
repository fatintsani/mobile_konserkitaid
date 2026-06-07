import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Edit2, Trash2, RefreshCcw } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const Categories = () => {
  const { t } = useTranslation();
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({});
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    name_en: '',
    icon_file: null,
    icon_preview: '',
    description: '',
    description_en: '',
    status: 'active'
  });

  const fetchCategories = async (pageUrl = null) => {
    setLoading(true);
    try {
      const url = pageUrl || `/admin/event-categories?page=1`;
      const response = await api.get(url);
      if (response.data.success) {
        setCategories(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch categories', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
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
        icon_file: file,
        icon_preview: URL.createObjectURL(file) 
      });
    }
  };

  const handleCreate = () => {
    setEditingId(null);
    setFormData({ name: '', name_en: '', icon_file: null, icon_preview: '', description: '', description_en: '', status: 'active' });
    setShowModal(true);
  };

  const handleEdit = (category) => {
    setEditingId(category.id);
    setFormData({
      name: category.name,
      name_en: category.name_en || '',
      icon_file: null,
      icon_preview: category.icon || '',
      description: category.description || '',
      description_en: category.description_en || '',
      status: category.status
    });
    setShowModal(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this category?')) return;
    try {
      const response = await api.delete(`/admin/event-categories/${id}`);
      if (response.data.success) fetchCategories();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to delete category');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const data = new FormData();
      data.append('name', formData.name);
      data.append('name_en', formData.name_en);
      data.append('status', formData.status);
      if (formData.description) data.append('description', formData.description);
      if (formData.description_en) data.append('description_en', formData.description_en);
      
      if (formData.icon_file) {
        data.append('icon', formData.icon_file);
      }

      if (editingId) {
        data.append('_method', 'PUT');
        await api.post(`/admin/event-categories/${editingId}`, data, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
      } else {
        await api.post(`/admin/event-categories`, data, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
      }
      setShowModal(false);
      fetchCategories();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to save category');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">Category Management</h1>
        <div className="flex space-x-2">
          <button onClick={() => fetchCategories()} className="p-2 text-gray-500 hover:text-[#6C2BD9] bg-white rounded-full shadow-sm">
            <RefreshCcw size={20} />
          </button>
          <button onClick={handleCreate} className="flex items-center px-4 py-2 bg-[#6C2BD9] text-white rounded-lg hover:bg-[#5b24b8] shadow-sm">
            <Plus size={18} className="mr-2" /> Add Category
          </button>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 flex justify-center"><RefreshCcw className="animate-spin text-[#6C2BD9]" size={32} /></div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Category Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Slug</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {categories.length === 0 ? (
                  <tr><td colSpan="4" className="px-6 py-8 text-center text-gray-500">No categories found.</td></tr>
                ) : (
                  categories.map((category) => (
                    <tr key={category.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          {category.icon && <img src={category.icon} alt="icon" className="w-6 h-6 mr-3" />}
                          <div>
                            <div className="text-sm font-medium text-gray-900">{category.name}</div>
                            <div className="text-xs text-gray-500">{category.description || '-'}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {category.slug}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          category.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                        }`}>
                          {category.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          <button onClick={() => handleEdit(category)} className="text-blue-600 hover:text-blue-900 bg-blue-50 p-1.5 rounded-md">
                            <Edit2 size={18} />
                          </button>
                          <button onClick={() => handleDelete(category.id)} className="text-red-600 hover:text-red-900 bg-red-50 p-1.5 rounded-md">
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
        <div className="flex items-center justify-between bg-white px-4 py-3 border border-gray-100 rounded-xl shadow-sm sm:px-6">
          <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p className="text-sm text-gray-700">
                Showing <span className="font-medium">{pagination.from}</span> to <span className="font-medium">{pagination.to}</span> of <span className="font-medium">{pagination.total}</span> results
              </p>
            </div>
            <div>
              <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                <button
                  onClick={() => fetchCategories(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchCategories(pagination.next_page_url)}
                  disabled={!pagination.next_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
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
            <div className="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75" onClick={() => setShowModal(false)} />
            <div className="relative inline-block w-full max-w-md p-6 overflow-hidden text-left align-middle transition-all transform bg-white shadow-xl rounded-2xl">
              <h3 className="text-lg font-medium leading-6 text-gray-900 mb-4">
                {editingId ? 'Edit Category' : 'Add Category'}
              </h3>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('forms.name_id')}</label>
                  <input type="text" name="name" required value={formData.name} onChange={handleInputChange} className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('forms.name_en')}</label>
                  <input type="text" name="name_en" value={formData.name_en} onChange={handleInputChange} className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('forms.description_id')}</label>
                  <input type="text" name="description" value={formData.description} onChange={handleInputChange} className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('forms.description_en')}</label>
                  <input type="text" name="description_en" value={formData.description_en} onChange={handleInputChange} className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Icon (Optional)</label>
                  <input type="file" name="icon" accept="image/*" onChange={handleFileChange} className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border" />
                  {formData.icon_preview && <img src={formData.icon_preview} alt="Preview" className="mt-2 h-12 w-12 object-cover rounded" />}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Status</label>
                  <select name="status" value={formData.status} onChange={handleInputChange} className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border">
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
                <div className="mt-6 flex justify-end space-x-3">
                  <button type="button" onClick={() => setShowModal(false)} className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
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

export default Categories;
