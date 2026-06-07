import { useState, useEffect } from 'react';
import api from '../api/axios';
import { CheckCircle, XCircle, RefreshCcw, ShieldAlert, BadgeCheck } from 'lucide-react';

const Organizers = () => {
  const [organizers, setOrganizers] = useState([]);
  const [loading, setLoading] = useState(true);

  const [pagination, setPagination] = useState({});

  const fetchOrganizers = async (pageUrl = null) => {
    setLoading(true);
    try {
      const url = pageUrl || `/admin/organizers?page=1`;
      const response = await api.get(url);
      if (response.data.success) {
        setOrganizers(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch organizers', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrganizers(`/admin/organizers?page=1`);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleVerify = async (id) => {
    try {
      const response = await api.put(`/admin/organizers/${id}/verify`);
      if (response.data.success) fetchOrganizers();
    } catch (error) {
      alert('Failed to verify organizer');
    }
  };

  const handleReject = async (id) => {
    try {
      const response = await api.put(`/admin/organizers/${id}/reject`);
      if (response.data.success) fetchOrganizers();
    } catch (error) {
      alert('Failed to reject organizer');
    }
  };

  const handleSuspend = async (id) => {
    if (window.confirm('Are you sure you want to suspend this organizer?')) {
      try {
        const response = await api.put(`/admin/organizers/${id}/suspend`);
        if (response.data.success) fetchOrganizers();
      } catch (error) {
        alert('Failed to suspend organizer');
      }
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-800">Organizer Management</h1>
        <button onClick={fetchOrganizers} className="p-2 text-gray-500 hover:text-[#6C2BD9] bg-white rounded-full shadow-sm">
          <RefreshCcw size={20} />
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 flex justify-center"><RefreshCcw className="animate-spin text-[#6C2BD9]" size={32} /></div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Organization Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User Email</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Stats</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {organizers.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-8 text-center text-gray-500">No organizers found.</td>
                  </tr>
                ) : (
                  organizers.map((org) => (
                    <tr key={org.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900 flex items-center">
                          {org.company_name}
                          {org.verification_badge && <BadgeCheck className="w-4 h-4 text-blue-500 ml-1" />}
                        </div>
                        <div className="text-xs text-gray-500">{org.public_name}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-500">{org.user?.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-xs text-gray-500">{org.events_count || 0} Events</div>
                        <div className="text-xs text-gray-500">{org.followers_count || 0} Followers</div>
                        <div className="text-xs text-gray-500">{org.reviews_count || 0} Reviews</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          org.status === 'verified' ? 'bg-green-100 text-green-800' : 
                          org.status === 'rejected' ? 'bg-orange-100 text-orange-800' :
                          org.status === 'suspended' ? 'bg-red-100 text-red-800' :
                          'bg-yellow-100 text-yellow-800'
                        }`}>
                          {org.status?.toUpperCase() || 'PENDING'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          {org.status !== 'verified' && (
                            <button onClick={() => handleVerify(org.id)} className="text-green-600 hover:text-green-900 bg-green-50 p-1.5 rounded-md" title="Verify">
                              <CheckCircle size={18} />
                            </button>
                          )}
                          {org.status !== 'rejected' && (
                            <button onClick={() => handleReject(org.id)} className="text-orange-600 hover:text-orange-900 bg-orange-50 p-1.5 rounded-md" title="Reject">
                              <XCircle size={18} />
                            </button>
                          )}
                          {org.status !== 'suspended' && (
                            <button onClick={() => handleSuspend(org.id)} className="text-red-600 hover:text-red-900 bg-red-50 p-1.5 rounded-md" title="Suspend">
                              <ShieldAlert size={18} />
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
                  onClick={() => fetchOrganizers(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchOrganizers(pagination.next_page_url)}
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
    </div>
  );
};

export default Organizers;
