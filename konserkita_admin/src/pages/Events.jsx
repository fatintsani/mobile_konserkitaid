import { useState, useEffect } from 'react';
import api from '../api/axios';
import { CheckCircle, XCircle, Trash2, RefreshCcw, MapPin } from 'lucide-react';
import toast from 'react-hot-toast';

const Events = () => {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');

  const [pagination, setPagination] = useState({});
  
  // Venue Assignment State
  const [isVenueModalOpen, setIsVenueModalOpen] = useState(false);
  const [currentEventForVenue, setCurrentEventForVenue] = useState(null);
  const [venuesList, setVenuesList] = useState([]);
  const [selectedVenueId, setSelectedVenueId] = useState('');

  const fetchEvents = async (pageUrl = null) => {
    setLoading(true);
    try {
      let url = pageUrl || `/admin/events?page=1`;
      if (statusFilter && !pageUrl) url += `&status=${statusFilter}`;
      
      const response = await api.get(url);
      if (response.data.success) {
        setEvents(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch events', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEvents(`/admin/events?page=1${statusFilter ? `&status=${statusFilter}` : ''}`);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  const fetchVenuesList = async () => {
    try {
      const response = await api.get('/admin/venues');
      if (response.data.success) {
        setVenuesList(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch venues', error);
    }
  };

  const openVenueModal = (event) => {
    setCurrentEventForVenue(event);
    setSelectedVenueId(event.seatMap?.venue_id || '');
    if (venuesList.length === 0) fetchVenuesList();
    setIsVenueModalOpen(true);
  };

  const handleAssignVenue = async (e) => {
    e.preventDefault();
    if (!selectedVenueId) return toast.error('Please select a venue');
    
    try {
      await api.post(`/admin/events/${currentEventForVenue.id}/seat-map`, {
        venue_id: selectedVenueId
      });
      toast.success('Venue assigned successfully');
      setIsVenueModalOpen(false);
      fetchEvents();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to assign venue');
    }
  };

  const handleApprove = async (id) => {
    try {
      const response = await api.put(`/admin/events/${id}/approve`);
      if (response.data.success) fetchEvents();
    } catch (error) {
      alert('Failed to approve event');
    }
  };

  const handleReject = async (id) => {
    try {
      const response = await api.put(`/admin/events/${id}/reject`);
      if (response.data.success) fetchEvents();
    } catch (error) {
      alert('Failed to reject event');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this event?')) return;
    try {
      const response = await api.delete(`/admin/events/${id}`);
      if (response.data.success) fetchEvents();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to delete event');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">Events Management</h1>
        <div className="flex items-center space-x-4">
          <select 
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="border-gray-300 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border"
          >
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="published">Published</option>
            <option value="rejected">Rejected</option>
            <option value="cancelled">Cancelled</option>
          </select>
          <button onClick={fetchEvents} className="p-2 text-gray-500 hover:text-[#6C2BD9] bg-white rounded-full shadow-sm">
            <RefreshCcw size={20} />
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Event</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Organizer</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date & Time</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {events.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-8 text-center text-gray-500">No events found.</td>
                  </tr>
                ) : (
                  events.map((event) => (
                    <tr key={event.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{event.title}</div>
                        <div className="text-sm text-gray-500">{event.location}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{event.organizer?.organization_name || 'N/A'}</div>
                        <div className="text-xs text-gray-500">{event.organizer?.user?.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{event.date}</div>
                        <div className="text-sm text-gray-500">{event.time}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          event.status === 'published' ? 'bg-green-100 text-green-800' : 
                          event.status === 'pending' ? 'bg-yellow-100 text-yellow-800' : 'bg-red-100 text-red-800'
                        }`}>
                          {event.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          {event.status === 'pending' && (
                            <>
                              <button onClick={() => handleApprove(event.id)} className="text-green-600 hover:text-green-900 bg-green-50 p-1.5 rounded-md" title="Approve">
                                <CheckCircle size={18} />
                              </button>
                              <button onClick={() => handleReject(event.id)} className="text-orange-600 hover:text-orange-900 bg-orange-50 p-1.5 rounded-md" title="Reject">
                                <XCircle size={18} />
                              </button>
                            </>
                          )}
                          <button onClick={() => openVenueModal(event)} className="text-purple-600 hover:text-purple-900 bg-purple-50 p-1.5 rounded-md" title={event.seatMap ? "Change Venue" : "Assign Venue"}>
                            <MapPin size={18} />
                          </button>
                          <button onClick={() => handleDelete(event.id)} className="text-red-600 hover:text-red-900 bg-red-50 p-1.5 rounded-md" title="Delete">
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

      {/* Pagination Controls */}
      {!loading && pagination.total > 0 && (
        <div className="flex items-center justify-between bg-white px-4 py-3 border border-gray-100 rounded-xl shadow-sm sm:px-6">
          <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p className="text-sm text-gray-700">
                Showing <span className="font-medium">{pagination.from}</span> to <span className="font-medium">{pagination.to}</span> of{' '}
                <span className="font-medium">{pagination.total}</span> results
              </p>
            </div>
            <div>
              <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                <button
                  onClick={() => fetchEvents(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchEvents(pagination.next_page_url)}
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

      {/* Assign Venue Modal */}
      {isVenueModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900 bg-opacity-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden flex flex-col">
            <form onSubmit={handleAssignVenue} className="flex flex-col">
              <div className="px-6 py-4 border-b border-gray-100 flex-shrink-0">
                <h3 className="text-lg font-bold text-gray-900">Assign Venue to Event</h3>
                <p className="text-sm text-gray-500">{currentEventForVenue?.title}</p>
              </div>
              <div className="px-6 py-6 flex-1">
                <label className="block text-sm font-medium text-gray-700 mb-2">Select Master Venue</label>
                <select 
                  value={selectedVenueId} 
                  onChange={(e) => setSelectedVenueId(e.target.value)} 
                  className="block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9]"
                  required
                >
                  <option value="" disabled>-- Select a Venue --</option>
                  {venuesList.map(v => (
                    <option key={v.id} value={v.id}>{v.name} ({v.city})</option>
                  ))}
                </select>
                {currentEventForVenue?.seatMap && (
                  <p className="mt-2 text-sm text-green-600 flex items-center">
                    <CheckCircle size={14} className="mr-1" /> Currently assigned
                  </p>
                )}
              </div>
              <div className="px-6 py-4 bg-gray-50 border-t border-gray-100 flex justify-end space-x-3 flex-shrink-0">
                <button type="button" onClick={() => setIsVenueModalOpen(false)} className="px-4 py-2 bg-white border border-gray-300 rounded-md text-gray-700 font-medium hover:bg-gray-50 transition">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 bg-[#6C2BD9] text-white rounded-md font-medium hover:bg-purple-700 transition">
                  Save Assignment
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Events;
