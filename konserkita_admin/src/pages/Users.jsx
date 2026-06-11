import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Trash2, RefreshCcw } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [roleFilter, setRoleFilter] = useState('');
  const { user: currentUser } = useAuth();

  const [pagination, setPagination] = useState({});

  const fetchUsers = async (pageUrl = null) => {
    setLoading(true);
    try {
      let url = pageUrl || `/admin/users?page=1`;
      if (roleFilter && !pageUrl) url += `&role=${roleFilter}`;

      const response = await api.get(url);
      if (response.data.success) {
        setUsers(response.data.data.data);
        setPagination(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch users', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers(`/admin/users?page=1${roleFilter ? `&role=${roleFilter}` : ''}`);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [roleFilter]);

  const handleRoleChange = async (id, newRole) => {
    try {
      const response = await api.put(`/admin/users/${id}`, { role: newRole });
      if (response.data.success) fetchUsers();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to update user role');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this user? This cannot be undone.')) return;
    try {
      const response = await api.delete(`/admin/users/${id}`);
      if (response.data.success) fetchUsers();
    } catch (error) {
      alert(error.response?.data?.message || 'Failed to delete user');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-white/90">User Management</h1>
        <div className="flex items-center space-x-4">
          <select 
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="border-white/20 rounded-md shadow-sm focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-3 py-2 border"
          >
            <option value="">All Roles</option>
            <option value="customer">Customer</option>
            <option value="organizer">Organizer</option>
            <option value="admin">Admin</option>
            <option value="super_admin">Super Admin</option>
          </select>
          <button onClick={fetchUsers} className="p-2 text-white/60 hover:text-[#6C2BD9] bg-[#141416] border border-white/5 rounded-full shadow-sm">
            <RefreshCcw size={20} />
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Email</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Role</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Joined At</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-white/60 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-[#141416] border border-white/5 divide-y divide-white/10">
                {users.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="px-6 py-8 text-center text-white/60">No users found.</td>
                  </tr>
                ) : (
                  users.map((u) => (
                    <tr key={u.id} className="hover:bg-[#1C1C1F]">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-white">{u.name}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-white/60">{u.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <select
                          value={u.role}
                          onChange={(e) => handleRoleChange(u.id, e.target.value)}
                          disabled={
                            u.id === currentUser?.id || 
                            (u.role === 'super_admin' && currentUser?.role !== 'super_admin')
                          }
                          className="text-sm border-white/20 rounded focus:ring-[#6C2BD9] focus:border-[#6C2BD9] px-2 py-1 border disabled:bg-[#2A2A2D]"
                        >
                          <option value="customer">Customer</option>
                          <option value="organizer">Organizer</option>
                          <option value="admin">Admin</option>
                          {currentUser?.role === 'super_admin' && <option value="super_admin">Super Admin</option>}
                        </select>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-white/60">
                        {new Date(u.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          <button 
                            onClick={() => handleDelete(u.id)} 
                            disabled={u.id === currentUser?.id}
                            className="text-red-600 hover:text-red-900 bg-red-500/10 p-1.5 rounded-md disabled:opacity-50 disabled:cursor-not-allowed" 
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
                  onClick={() => fetchUsers(pagination.prev_page_url)}
                  disabled={!pagination.prev_page_url}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-white/20 bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => fetchUsers(pagination.next_page_url)}
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

export default Users;
