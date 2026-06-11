import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../api/axios';
import { Plus, Trash2, Edit, RefreshCcw, MapPin, Eye } from 'lucide-react';
import toast from 'react-hot-toast';

const Venues = () => {
  const [venues, setVenues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentVenue, setCurrentVenue] = useState(null);

  const [formData, setFormData] = useState({
    name: '',
    city: '',
    address: '',
    capacity: '',
    status: 'active'
  });

  const fetchVenues = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/venues');
      if (response.data.success) {
        setVenues(response.data.data);
      }
    } catch (error) {
      toast.error('Failed to fetch venues');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVenues();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const openModal = (venue = null) => {
    if (venue) {
      setCurrentVenue(venue);
      setFormData({
        name: venue.name,
        city: venue.city,
        address: venue.address,
        capacity: venue.capacity || '',
        status: venue.status
      });
    } else {
      setCurrentVenue(null);
      setFormData({
        name: '',
        city: '',
        address: '',
        capacity: '',
        status: 'active'
      });
    }
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setCurrentVenue(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = { ...formData, capacity: formData.capacity ? parseInt(formData.capacity) : null };
      
      if (currentVenue) {
        await api.put(`/admin/venues/${currentVenue.id}`, payload);
        toast.success('Venue updated successfully');
      } else {
        await api.post('/admin/venues', payload);
        toast.success('Venue created successfully');
      }
      closeModal();
      fetchVenues();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to save venue');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this venue? It will also delete all its sections and seats.')) return;
    
    try {
      await api.delete(`/admin/venues/${id}`);
      toast.success('Venue deleted successfully');
      fetchVenues();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to delete venue');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white/90">Venues Master Data</h1>
        <div className="flex items-center space-x-4">
          <button onClick={fetchVenues} className="p-2 text-white/60 hover:text-[#6C2BD9] bg-[#141416] border border-white/5 rounded-full shadow-sm">
            <RefreshCcw size={20} />
          </button>
          <button 
            onClick={() => openModal()}
            className="flex items-center px-4 py-2 bg-[#6C2BD9] text-white rounded-lg hover:bg-purple-700 transition"
          >
            <Plus size={18} className="mr-2" />
            Add Venue
          </button>
        </div>
      </div>

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
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          {venues.map((venue) => (
            <div key={venue.id} className="bg-[#141416] border border-white/5 rounded-xl shadow-sm border border-white/5 overflow-hidden hover:shadow-md transition flex flex-col">
              <div className="p-6 flex-1">
                <div className="flex justify-between items-start mb-5">
                  <div className="flex items-center">
                    <div className="p-2.5 bg-purple-500/10 rounded-lg text-[#6C2BD9] mr-3">
                      <MapPin size={20} />
                    </div>
                    <div>
                      <h3 className="font-bold text-white text-lg leading-tight">{venue.name}</h3>
                      <p className="text-sm text-white/60 mt-0.5">{venue.city}</p>
                    </div>
                  </div>
                  <span className={`inline-flex items-center px-2.5 py-1 text-xs font-medium rounded-full ${venue.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                    {venue.status}
                  </span>
                </div>
                
                <div className="space-y-3 mb-2">
                  <div className="flex items-start">
                    <span className="text-sm font-medium text-white/60 w-20 flex-shrink-0">Address</span>
                    <span className="text-sm text-white line-clamp-2">{venue.address}</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-sm font-medium text-white/60 w-20 flex-shrink-0">Capacity</span>
                    <span className="text-sm text-white">{venue.capacity ? venue.capacity.toLocaleString() : '-'}</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-sm font-medium text-white/60 w-20 flex-shrink-0">Sections</span>
                    <span className="text-sm text-white bg-[#2A2A2D] px-2 py-0.5 rounded-md font-medium">{venue.sections?.length || 0}</span>
                  </div>
                </div>
              </div>

              <div className="px-6 py-4 bg-[#1C1C1F] border-t border-white/5 flex justify-between items-center mt-auto">
                <Link 
                  to={`/venues/${venue.id}`}
                  className="inline-flex items-center text-[#6C2BD9] hover:text-purple-800 font-semibold text-sm transition-colors"
                >
                  <Eye size={16} className="mr-1.5" /> Manage Sections
                </Link>
                <div className="flex items-center space-x-1">
                  <button onClick={() => openModal(venue)} className="p-2 text-white/50 hover:text-blue-600 hover:bg-blue-500/10 rounded-lg transition-colors">
                    <Edit size={16} />
                  </button>
                  <button onClick={() => handleDelete(venue.id)} className="p-2 text-white/50 hover:text-red-600 hover:bg-red-500/10 rounded-lg transition-colors">
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Form */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900 bg-opacity-50">
          <div className="bg-[#141416] border border-white/5 rounded-xl shadow-xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
            <form onSubmit={handleSubmit} className="flex flex-col h-full">
              <div className="px-6 py-4 border-b border-white/5 flex-shrink-0">
                <h3 className="text-lg font-bold text-white">
                  {currentVenue ? 'Edit Venue' : 'Create New Venue'}
                </h3>
              </div>
              <div className="px-6 py-4 overflow-y-auto flex-1">
                <div className="space-y-4">
                        <div>
                          <label className="block text-sm font-medium text-white/80">Venue Name</label>
                          <input type="text" name="name" required value={formData.name} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9]" />
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-white/80">City</label>
                          <input type="text" name="city" required value={formData.city} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9]" />
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-white/80">Address</label>
                          <textarea name="address" required rows="3" value={formData.address} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9]"></textarea>
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <label className="block text-sm font-medium text-white/80">Capacity (Optional)</label>
                            <input type="number" name="capacity" value={formData.capacity} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9]" />
                          </div>
                          <div>
                            <label className="block text-sm font-medium text-white/80">Status</label>
                            <select name="status" value={formData.status} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9]">
                              <option value="active">Active</option>
                              <option value="inactive">Inactive</option>
                            </select>
                          </div>
                        </div>
                      </div>
              </div>
              <div className="px-6 py-4 bg-[#1C1C1F] border-t border-white/5 flex justify-end space-x-3 flex-shrink-0">
                <button type="button" onClick={closeModal} className="px-4 py-2 bg-[#141416] border border-white/5 border border-white/20 rounded-md text-white/80 font-medium hover:bg-[#1C1C1F] transition">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 bg-[#6C2BD9] text-white rounded-md font-medium hover:bg-purple-700 transition">
                  {currentVenue ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Venues;
