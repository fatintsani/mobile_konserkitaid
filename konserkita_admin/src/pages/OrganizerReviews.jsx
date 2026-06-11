import { useState, useEffect } from 'react';
import api from '../api/axios';
import { CheckCircle, XCircle, RefreshCcw } from 'lucide-react';

const OrganizerReviews = () => {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);

  const [pagination, setPagination] = useState({});

  const fetchReviews = async (pageUrl = null) => {
    setLoading(true);
    try {
      const url = pageUrl || `/admin/organizer-reviews?page=1`;
      const response = await api.get(url);
      if (response.data.success) {
        setReviews(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch reviews', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReviews();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleApprove = async (id) => {
    try {
      const response = await api.put(`/admin/organizer-reviews/${id}/approve`);
      if (response.data.success) fetchReviews();
    } catch (error) {
      alert('Failed to approve review');
    }
  };

  const handleReject = async (id) => {
    try {
      const response = await api.put(`/admin/organizer-reviews/${id}/reject`);
      if (response.data.success) fetchReviews();
    } catch (error) {
      alert('Failed to reject review');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white/90">Organizer Reviews</h1>
        <button onClick={() => fetchReviews()} className="p-2 text-white/60 hover:text-[#6C2BD9] bg-[#141416] border border-white/5 rounded-full shadow-sm">
          <RefreshCcw size={20} />
        </button>
      </div>

      <div className="bg-[#141416] border border-white/5 rounded-xl shadow-sm border border-white/5 overflow-hidden">
        {loading ? (
          <div className="p-8 flex justify-center"><RefreshCcw className="animate-spin text-[#6C2BD9]" size={32} /></div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-white/10">
              <thead className="bg-[#1C1C1F]">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">User</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Organizer</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Rating & Comment</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-white/60 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                {reviews.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-8 text-center text-white/60">No reviews found.</td>
                  </tr>
                ) : (
                  reviews.map((review) => (
                    <tr key={review.id} className="hover:bg-[#1C1C1F]">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">{review.user?.name}</div>
                        <div className="text-xs text-white/60">{review.user?.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-white">{review.organizer?.public_name || review.organizer?.company_name}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm font-bold text-orange-500">{review.rating} Stars</div>
                        <div className="text-sm text-white/70 line-clamp-2">{review.comment}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          review.status === 'approved' ? 'bg-green-100 text-green-800' :
                          review.status === 'rejected' ? 'bg-red-100 text-red-800' :
                          'bg-yellow-100 text-yellow-800'
                        }`}>
                          {review.status?.toUpperCase() || 'PENDING'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          {review.status === 'pending' && (
                            <>
                              <button onClick={() => handleApprove(review.id)} className="text-green-600 hover:text-green-900 bg-green-500/10 p-1.5 rounded-md" title="Approve">
                                <CheckCircle size={18} />
                              </button>
                              <button onClick={() => handleReject(review.id)} className="text-red-600 hover:text-red-900 bg-red-500/10 p-1.5 rounded-md" title="Reject">
                                <XCircle size={18} />
                              </button>
                            </>
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
                  onClick={() => fetchReviews(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-white/20 bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchReviews(pagination.next_page_url)}
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
    </div>
  );
};

export default OrganizerReviews;
