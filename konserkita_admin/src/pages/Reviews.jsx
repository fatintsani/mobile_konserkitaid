import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { CheckCircle, XCircle, Trash2, Search, Filter, MessageSquare } from 'lucide-react';
import toast from 'react-hot-toast';

function Reviews() {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({});
  const [filters, setFilters] = useState({
    status: '',
    rating: '',
    page: 1,
  });
  
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [selectedReview, setSelectedReview] = useState(null);
  const [adminNote, setAdminNote] = useState('');

  const fetchReviews = async () => {
    try {
      setLoading(true);
      let url = `/admin/reviews?page=${filters.page}`;
      if (filters.status) url += `&status=${filters.status}`;
      if (filters.rating) url += `&rating=${filters.rating}`;

      const response = await api.get(url);
      if (response.data.success) {
        setReviews(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      toast.error('Failed to fetch reviews');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReviews();
  }, [filters]);

  const handleApprove = async (id) => {
    if (!window.confirm('Are you sure you want to approve this review?')) return;
    try {
      const response = await api.put(`/admin/reviews/${id}/approve`);
      if (response.data.success) {
        toast.success('Review approved successfully');
        fetchReviews();
      }
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to approve review');
    }
  };

  const handleRejectClick = (review) => {
    setSelectedReview(review);
    setAdminNote('');
    setShowRejectModal(true);
  };

  const handleRejectSubmit = async (e) => {
    e.preventDefault();
    if (!adminNote) {
      toast.error('Admin note is required');
      return;
    }
    try {
      const response = await api.put(`/admin/reviews/${selectedReview.id}/reject`, { admin_note: adminNote });
      if (response.data.success) {
        toast.success('Review rejected successfully');
        setShowRejectModal(false);
        fetchReviews();
      }
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to reject review');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this review permanently?')) return;
    try {
      const response = await api.delete(`/admin/reviews/${id}`);
      if (response.data.success) {
        toast.success('Review deleted successfully');
        fetchReviews();
      }
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to delete review');
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800';
      case 'rejected': return 'bg-red-100 text-red-800';
      default: return 'bg-yellow-100 text-yellow-800';
    }
  };

  const renderStars = (rating) => {
    return '⭐'.repeat(rating);
  };

  return (
    <div>
      <div className="sm:flex sm:items-center">
        <div className="sm:flex-auto">
          <h1 className="text-2xl font-semibold text-white">Reviews & Ratings</h1>
          <p className="mt-2 text-sm text-white/80">
            Manage customer reviews for events.
          </p>
        </div>
      </div>

      <div className="mt-4 flex flex-col sm:flex-row gap-4 mb-6">
        <div className="w-full sm:w-48">
          <label className="block text-sm font-medium text-white/80 mb-1">Status</label>
          <select
            className="mt-1 block w-full rounded-md border-white/20 shadow-sm focus:border-purple-500 focus:ring-purple-500 sm:text-sm"
            value={filters.status}
            onChange={(e) => setFilters({ ...filters, status: e.target.value, page: 1 })}
          >
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>

        <div className="w-full sm:w-48">
          <label className="block text-sm font-medium text-white/80 mb-1">Rating</label>
          <select
            className="mt-1 block w-full rounded-md border-white/20 shadow-sm focus:border-purple-500 focus:ring-purple-500 sm:text-sm"
            value={filters.rating}
            onChange={(e) => setFilters({ ...filters, rating: e.target.value, page: 1 })}
          >
            <option value="">All Ratings</option>
            <option value="5">5 Stars</option>
            <option value="4">4 Stars</option>
            <option value="3">3 Stars</option>
            <option value="2">2 Stars</option>
            <option value="1">1 Star</option>
          </select>
        </div>
      </div>

      <div className="mt-8 flex flex-col">
        <div className="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div className="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
            <div className="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
              <table className="min-w-full divide-y divide-gray-300">
                <thead className="bg-[#1C1C1F]">
                  <tr>
                    <th className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-white sm:pl-6">Event & User</th>
                    <th className="px-3 py-3.5 text-left text-sm font-semibold text-white">Rating</th>
                    <th className="px-3 py-3.5 text-left text-sm font-semibold text-white">Comment</th>
                    <th className="px-3 py-3.5 text-left text-sm font-semibold text-white">Status</th>
                    <th className="relative py-3.5 pl-3 pr-4 sm:pr-6">
                      <span className="sr-only">Actions</span>
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/10 bg-[#141416] border border-white/5">
                  {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="animate-pulse border-b border-white/5">
                    <td colSpan="10" className="px-6 py-5">
                      <div className="flex space-x-4">
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                        <div className="h-4 bg-white/5 rounded w-1/5"></div>
                      </div>
                    </td>
                  </tr>
                ))
              ) : reviews.length === 0 ? (
                    <tr>
                      <td colSpan="5" className="py-4 text-center text-sm text-white/60">No reviews found.</td>
                    </tr>
                  ) : (
                    reviews.map((review) => (
                      <tr key={review.id}>
                        <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm sm:pl-6">
                          <div className="font-medium text-white">{review.event?.title}</div>
                          <div className="text-white/60">by {review.user?.name}</div>
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-white/60">
                          {renderStars(review.rating)}
                        </td>
                        <td className="px-3 py-4 text-sm text-white/60 max-w-xs truncate" title={review.comment}>
                          {review.comment || '-'}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm">
                          <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${getStatusColor(review.status)}`}>
                            {review.status}
                          </span>
                        </td>
                        <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                          <div className="flex justify-end gap-2">
                            {review.status === 'pending' && (
                              <>
                                <button
                                  onClick={() => handleApprove(review.id)}
                                  className="text-green-600 hover:text-green-900 bg-green-500/10 p-1.5 rounded-md"
                                  title="Approve"
                                >
                                  <CheckCircle size={18} />
                                </button>
                                <button
                                  onClick={() => handleRejectClick(review)}
                                  className="text-yellow-600 hover:text-yellow-900 bg-yellow-500/10 p-1.5 rounded-md"
                                  title="Reject"
                                >
                                  <XCircle size={18} />
                                </button>
                              </>
                            )}
                            <button
                              onClick={() => handleDelete(review.id)}
                              className="text-red-600 hover:text-red-900 bg-red-500/10 p-1.5 rounded-md"
                              title="Delete"
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
            
            {/* Pagination */}
            {!loading && pagination.last_page > 1 && (
              <div className="mt-4 flex items-center justify-between bg-[#141416] border border-white/5 px-4 py-3 sm:px-6 rounded-lg shadow">
                <div className="flex flex-1 justify-between sm:hidden">
                  <button
                    onClick={() => setFilters({...filters, page: pagination.current_page - 1})}
                    disabled={pagination.current_page === 1}
                    className="relative inline-flex items-center rounded-md border border-white/20 bg-[#141416] border border-white/5 px-4 py-2 text-sm font-medium text-white/80 hover:bg-[#1C1C1F] disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => setFilters({...filters, page: pagination.current_page + 1})}
                    disabled={pagination.current_page === pagination.last_page}
                    className="relative ml-3 inline-flex items-center rounded-md border border-white/20 bg-[#141416] border border-white/5 px-4 py-2 text-sm font-medium text-white/80 hover:bg-[#1C1C1F] disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
                <div className="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
                  <div>
                    <p className="text-sm text-white/80">
                      Showing page <span className="font-medium">{pagination.current_page}</span> of <span className="font-medium">{pagination.last_page}</span>
                    </p>
                  </div>
                  <div>
                    <nav className="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
                      <button
                        onClick={() => setFilters({...filters, page: pagination.current_page - 1})}
                        disabled={pagination.current_page === 1}
                        className="relative inline-flex items-center rounded-l-md px-2 py-2 text-white/50 ring-1 ring-inset ring-gray-300 hover:bg-[#1C1C1F] focus:z-20 focus:outline-offset-0 disabled:opacity-50"
                      >
                        <span className="sr-only">Previous</span>
                        Previous
                      </button>
                      <button
                        onClick={() => setFilters({...filters, page: pagination.current_page + 1})}
                        disabled={pagination.current_page === pagination.last_page}
                        className="relative inline-flex items-center rounded-r-md px-2 py-2 text-white/50 ring-1 ring-inset ring-gray-300 hover:bg-[#1C1C1F] focus:z-20 focus:outline-offset-0 disabled:opacity-50"
                      >
                        <span className="sr-only">Next</span>
                        Next
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Reject Modal */}
      {showRejectModal && (
        <div className="fixed inset-0 bg-[#1C1C1F]0 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-[#141416] border border-white/5 rounded-lg max-w-md w-full p-6">
            <h3 className="text-lg font-medium text-white mb-4">Reject Review</h3>
            <form onSubmit={handleRejectSubmit}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-white/80 mb-2">
                  Reason for rejection
                </label>
                <textarea
                  required
                  rows={4}
                  className="w-full rounded-md border-white/20 shadow-sm focus:border-purple-500 focus:ring-purple-500 sm:text-sm p-2 border"
                  value={adminNote}
                  onChange={(e) => setAdminNote(e.target.value)}
                  placeholder="Explain why this review is rejected..."
                />
              </div>
              <div className="flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowRejectModal(false)}
                  className="rounded-md border border-white/20 bg-[#141416] border border-white/5 px-4 py-2 text-sm font-medium text-white/80 hover:bg-[#1C1C1F]"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="rounded-md border border-transparent bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
                >
                  Reject Review
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default Reviews;
