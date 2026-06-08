import React, { useState, useEffect } from 'react';
import { startRegistration } from '@simplewebauthn/browser';
import api from '../api/axios';
import { Fingerprint, Trash2, Plus, Key } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const Profile = () => {
  const { user } = useAuth();
  const [passkeys, setPasskeys] = useState([]);
  const [loading, setLoading] = useState(true);
  const [registering, setRegistering] = useState(false);
  const [error, setError] = useState('');

  const fetchPasskeys = async () => {
    try {
      const response = await api.get('/passkeys');
      setPasskeys(response.data);
    } catch (err) {
      console.error('Failed to fetch passkeys', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPasskeys();
  }, []);

  const handleAddPasskey = async () => {
    setError('');
    setRegistering(true);
    try {
      // 1. Get options from server
      const optionsRes = await api.post('/passkeys/register/options');
      const options = optionsRes.data;

      // 2. Pass options to authenticator
      const attResp = await startRegistration(options);

      // 3. Send authenticator response back to server to verify
      await api.post('/passkeys/register/verify', {
        ...attResp,
        name: `Passkey - ${new Date().toLocaleDateString()}`
      });

      fetchPasskeys();
    } catch (err) {
      console.error('Registration failed:', err);
      setError(err.message || 'Failed to register passkey. Ensure your device supports it.');
    } finally {
      setRegistering(false);
    }
  };

  const handleDeletePasskey = async (id) => {
    if (!window.confirm('Are you sure you want to delete this passkey?')) return;
    try {
      await api.delete(`/passkeys/${id}`);
      fetchPasskeys();
    } catch (err) {
      console.error('Failed to delete passkey', err);
      setError('Failed to delete passkey');
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Profile Settings</h1>
      
      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold text-gray-800 mb-4 flex items-center">
          <Key className="mr-2" size={20} />
          Passkeys / WebAuthn
        </h2>
        <p className="text-gray-600 mb-6 text-sm">
          Passkeys allow you to securely log in without a password using your device's fingerprint, face recognition, or screen lock.
        </p>

        {error && (
          <div className="bg-red-50 text-red-700 p-3 rounded mb-4 text-sm">
            {error}
          </div>
        )}

        <div className="space-y-4">
          {loading ? (
            <p className="text-gray-500">Loading passkeys...</p>
          ) : passkeys.length === 0 ? (
            <p className="text-gray-500 italic">No passkeys registered yet.</p>
          ) : (
            passkeys.map(pk => (
              <div key={pk.id} className="flex items-center justify-between p-4 border rounded-lg bg-gray-50">
                <div className="flex items-center space-x-3">
                  <Fingerprint className="text-[#6C2BD9]" size={24} />
                  <div>
                    <p className="font-medium text-gray-900">{pk.name}</p>
                    <p className="text-xs text-gray-500">
                      Created: {new Date(pk.created_at).toLocaleDateString()}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => handleDeletePasskey(pk.id)}
                  className="text-red-500 hover:text-red-700 p-2"
                  title="Delete Passkey"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            ))
          )}
        </div>

        <button
          onClick={handleAddPasskey}
          disabled={registering}
          className="mt-6 flex items-center px-4 py-2 bg-[#6C2BD9] text-white rounded-lg hover:bg-[#5b24b8] disabled:opacity-50"
        >
          <Plus size={18} className="mr-2" />
          {registering ? 'Registering...' : 'Add New Passkey'}
        </button>
      </div>
    </div>
  );
};

export default Profile;
