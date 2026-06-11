import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { ArrowLeft, Plus, Settings, Check, RefreshCcw, MapPin } from 'lucide-react';
import toast from 'react-hot-toast';

const VenueDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [venue, setVenue] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [generatingFor, setGeneratingFor] = useState(null); // section ID being generated

  const [formData, setFormData] = useState({
    name: '',
    label: '',
    row_count: 5,
    seats_per_row: 10,
    status: 'active'
  });

  const fetchVenue = async () => {
    try {
      const response = await api.get(`/admin/venues/${id}`);
      if (response.data.success) {
        setVenue(response.data.data);
      }
    } catch (error) {
      toast.error('Failed to fetch venue details');
      navigate('/venues');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVenue();
  }, [id]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleAddSection = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...formData,
        row_count: parseInt(formData.row_count),
        seats_per_row: parseInt(formData.seats_per_row),
      };
      await api.post(`/admin/venues/${id}/sections`, payload);
      toast.success('Section created successfully');
      setIsModalOpen(false);
      setFormData({ name: '', label: '', row_count: 5, seats_per_row: 10, status: 'active' });
      fetchVenue();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to add section');
    }
  };

  const generateSeats = async (sectionId) => {
    if (!window.confirm('Are you sure? This will delete all existing seats in this section and regenerate them.')) return;
    
    setGeneratingFor(sectionId);
    try {
      const response = await api.post(`/admin/sections/${sectionId}/generate-seats`);
      toast.success(`Successfully generated ${response.data.data.total_seats} seats`);
      fetchVenue();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to generate seats');
    } finally {
      setGeneratingFor(null);
    }
  };

  if (loading) {
    return (
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
    );
  }

  if (!venue) return null;

  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <button onClick={() => navigate('/venues')} className="p-2 bg-[#141416] border border-white/5 rounded-full shadow-sm hover:text-[#6C2BD9]">
          <ArrowLeft size={20} />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-white/90">{venue.name}</h1>
          <p className="text-white/60">{venue.city} • {venue.address}</p>
        </div>
      </div>

      <div className="bg-[#141416] border border-white/5 rounded-xl shadow-sm border border-white/5 p-6">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-lg font-bold text-white/90">Sections & Seats</h2>
          <button 
            onClick={() => setIsModalOpen(true)}
            className="flex items-center px-4 py-2 bg-[#6C2BD9] text-white rounded-lg hover:bg-purple-700 transition"
          >
            <Plus size={18} className="mr-2" />
            Add Section
          </button>
        </div>

        {venue.sections && venue.sections.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {venue.sections.map(section => (
              <div key={section.id} className="border border-white/10 rounded-lg p-5">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="font-bold text-white text-lg">{section.name}</h3>
                    <p className="text-sm text-white/60">Label: {section.label}</p>
                  </div>
                  <span className={`px-2 py-1 text-xs font-semibold rounded-full ${section.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                    {section.status}
                  </span>
                </div>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div className="bg-[#1C1C1F] p-3 rounded-md text-center">
                    <p className="text-xs text-white/60 uppercase font-semibold">Rows</p>
                    <p className="text-xl font-bold text-white/90">{section.row_count}</p>
                  </div>
                  <div className="bg-[#1C1C1F] p-3 rounded-md text-center">
                    <p className="text-xs text-white/60 uppercase font-semibold">Seats / Row</p>
                    <p className="text-xl font-bold text-white/90">{section.seats_per_row}</p>
                  </div>
                </div>
                
                <div className="flex items-center justify-between mt-4 pt-4 border-t border-white/5">
                  <div className="text-sm">
                    <span className="font-semibold text-white/80">Total Seats Generated: </span>
                    <span className={section.seats?.length > 0 ? "text-green-600 font-bold" : "text-red-500 font-bold"}>
                      {section.seats?.length || 0}
                    </span>
                  </div>
                  <button 
                    onClick={() => generateSeats(section.id)}
                    disabled={generatingFor === section.id}
                    className="flex items-center px-3 py-1.5 bg-[#2A2A2D] hover:bg-gray-200 text-white/80 rounded text-sm font-medium transition disabled:opacity-50"
                  >
                    {generatingFor === section.id ? (
                      <RefreshCcw size={16} className="mr-1.5 animate-spin" />
                    ) : (
                      <Settings size={16} className="mr-1.5" />
                    )}
                    {section.seats?.length > 0 ? 'Regenerate Seats' : 'Generate Seats'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12 bg-[#1C1C1F] rounded-lg border border-dashed border-white/20">
            <MapPin size={48} className="mx-auto text-white/50 mb-3" />
            <p className="text-white/60 mb-4">No sections added to this venue yet.</p>
            <button 
              onClick={() => setIsModalOpen(true)}
              className="text-[#6C2BD9] font-medium hover:underline"
            >
              Add your first section
            </button>
          </div>
        )}
      </div>

      {/* Modal Add Section */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900 bg-opacity-50">
          <div className="bg-[#141416] border border-white/5 rounded-xl shadow-xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
            <form onSubmit={handleAddSection} className="flex flex-col h-full">
              <div className="px-6 py-4 border-b border-white/5 flex-shrink-0">
                <h3 className="text-lg font-bold text-white">Add Venue Section</h3>
              </div>
              <div className="px-6 py-4 overflow-y-auto flex-1">
                <div className="space-y-4">
                        <div>
                          <label className="block text-sm font-medium text-white/80">Section Name (e.g. VIP, Festival)</label>
                          <input type="text" name="name" required value={formData.name} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9]" />
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-white/80">Seat Label Prefix (e.g. VIP, FEST)</label>
                          <input type="text" name="label" required value={formData.label} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9]" />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <label className="block text-sm font-medium text-white/80">Number of Rows</label>
                            <input type="number" name="row_count" min="1" max="26" required value={formData.row_count} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9]" />
                            <p className="text-xs text-white/60 mt-1">Max 26 (A-Z)</p>
                          </div>
                          <div>
                            <label className="block text-sm font-medium text-white/80">Seats per Row</label>
                            <input type="number" name="seats_per_row" min="1" max="100" required value={formData.seats_per_row} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9]" />
                          </div>
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-white/80">Status</label>
                          <select name="status" value={formData.status} onChange={handleInputChange} className="mt-1 block w-full border border-white/20 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9]">
                            <option value="active">Active</option>
                            <option value="inactive">Inactive</option>
                          </select>
                        </div>
                      </div>
              </div>
              <div className="px-6 py-4 bg-[#1C1C1F] border-t border-white/5 flex justify-end space-x-3 flex-shrink-0">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 bg-[#141416] border border-white/5 border border-white/20 rounded-md text-white/80 font-medium hover:bg-[#1C1C1F] transition">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 bg-[#6C2BD9] text-white rounded-md font-medium hover:bg-purple-700 transition">
                  Create Section
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default VenueDetail;
