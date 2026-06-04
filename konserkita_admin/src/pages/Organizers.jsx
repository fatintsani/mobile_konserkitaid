import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { CheckCircle, XCircle, RefreshCcw } from 'lucide-react';

const Organizers = () => {
  const [organizers, setOrganizers] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchOrganizers = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/organizers');
      if (response.data.success) {
        setOrganizers(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch organizers', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrganizers();
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Contact Phone</th>
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
                        <div className="text-sm font-medium text-gray-900">{org.organization_name}</div>
                        <div className="text-xs text-gray-500 line-clamp-1 w-48" title={org.description}>{org.description}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-500">{org.user?.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-500">{org.contact_phone}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          org.is_verified ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                        }`}>
                          {org.is_verified ? 'Verified' : 'Unverified'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end space-x-2">
                          {!org.is_verified && (
                            <button onClick={() => handleVerify(org.id)} className="text-green-600 hover:text-green-900 bg-green-50 p-1.5 rounded-md" title="Verify">
                              <CheckCircle size={18} />
                            </button>
                          )}
                          {org.is_verified && (
                            <button onClick={() => handleReject(org.id)} className="text-orange-600 hover:text-orange-900 bg-orange-50 p-1.5 rounded-md" title="Revoke Verification">
                              <XCircle size={18} />
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
    </div>
  );
};

export default Organizers;
