import React, { useState, useEffect } from 'react';
import { startRegistration } from '@simplewebauthn/browser';
import api from '../api/axios';
import { Fingerprint, Trash2, Plus, Key, Smartphone, Monitor, History } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { securityService } from '../api/securityService';

const Profile = () => {
  const { user } = useAuth();
  const [passkeys, setPasskeys] = useState([]);
  const [loading, setLoading] = useState(true);
  const [registering, setRegistering] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  // 2FA states
  const [is2FAEnabled, setIs2FAEnabled] = useState(user?.two_factor_enabled || false);
  const [setupData, setSetupData] = useState(null);
  const [confirmCode, setConfirmCode] = useState('');
  const [recoveryCodes, setRecoveryCodes] = useState([]);

  const [sessions, setSessions] = useState([]);
  const [loadingSessions, setLoadingSessions] = useState(true);
  
  const [activities, setActivities] = useState([]);
  const [loadingActivities, setLoadingActivities] = useState(true);

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

  const fetchSessions = async () => {
    try {
      const data = await securityService.getSessions();
      setSessions(data);
    } catch (err) {
      console.error('Failed to fetch sessions', err);
    } finally {
      setLoadingSessions(false);
    }
  };

  const fetchActivities = async () => {
    try {
      const data = await securityService.getLoginActivities(1);
      setActivities(data.data || []);
    } catch (err) {
      console.error('Failed to fetch activities', err);
    } finally {
      setLoadingActivities(false);
    }
  };

  useEffect(() => {
    fetchPasskeys();
    fetchSessions();
    fetchActivities();
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

  const handleSetup2FA = async () => {
    setError('');
    setSuccessMsg('');
    try {
      const response = await api.post('/2fa/setup');
      setSetupData(response.data);
    } catch (err) {
      setError('Failed to setup 2FA');
    }
  };

  const handleConfirm2FA = async () => {
    setError('');
    setSuccessMsg('');
    try {
      const response = await api.post('/2fa/confirm', { code: confirmCode });
      setIs2FAEnabled(true);
      setRecoveryCodes(response.data.recovery_codes);
      setSetupData(null);
      setSuccessMsg('2FA has been successfully enabled.');
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to confirm 2FA code');
    }
  };

  const handleDisable2FA = async () => {
    if (!window.confirm('Are you sure you want to disable Two-Factor Authentication? This will reduce your account security.')) return;
    setError('');
    setSuccessMsg('');
    try {
      await api.post('/2fa/disable');
      setIs2FAEnabled(false);
      setRecoveryCodes([]);
      setSuccessMsg('2FA has been disabled.');
    } catch (err) {
      setError('Failed to disable 2FA');
    }
  };

  const handleRegenerateCodes = async () => {
    if (!window.confirm('Are you sure? Your old recovery codes will no longer work.')) return;
    setError('');
    setSuccessMsg('');
    try {
      const response = await api.post('/2fa/recovery-codes/regenerate');
      setRecoveryCodes(response.data.recovery_codes);
      setSuccessMsg('Recovery codes regenerated successfully. Please save them immediately.');
    } catch (err) {
      setError('Failed to regenerate recovery codes');
    }
  };

  const handleRevokeSession = async (id) => {
    if (!window.confirm('Are you sure you want to log out this device?')) return;
    try {
      await securityService.revokeSession(id);
      fetchSessions();
      setSuccessMsg('Session revoked successfully.');
    } catch (err) {
      setError('Failed to revoke session');
    }
  };

  const handleRevokeOtherSessions = async () => {
    if (!window.confirm('Are you sure you want to log out all other devices?')) return;
    try {
      await securityService.revokeOtherSessions();
      fetchSessions();
      setSuccessMsg('Other sessions revoked successfully.');
    } catch (err) {
      setError('Failed to revoke other sessions');
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-white">Profile Settings</h1>
      
      <div className="bg-[#141416] border border-white/5 shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold text-white/90 mb-4 flex items-center">
          <Key className="mr-2" size={20} />
          Passkeys / WebAuthn
        </h2>
        <p className="text-white/70 mb-6 text-sm">
          Passkeys allow you to securely log in without a password using your device's fingerprint, face recognition, or screen lock.
        </p>

        {error && (
          <div className="bg-red-500/10 text-red-700 p-3 rounded mb-4 text-sm">
            {error}
          </div>
        )}
        {successMsg && (
          <div className="bg-green-500/10 text-green-700 p-3 rounded mb-4 text-sm">
            {successMsg}
          </div>
        )}

        <div className="space-y-4">
          {loading ? (
            <p className="text-white/60">Loading passkeys...</p>
          ) : passkeys.length === 0 ? (
            <p className="text-white/60 italic">No passkeys registered yet.</p>
          ) : (
            passkeys.map(pk => (
              <div key={pk.id} className="flex items-center justify-between p-4 border rounded-lg bg-[#1C1C1F]">
                <div className="flex items-center space-x-3">
                  <Fingerprint className="text-[#6C2BD9]" size={24} />
                  <div>
                    <p className="font-medium text-white">{pk.name}</p>
                    <p className="text-xs text-white/60">
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

      {/* 2FA Settings Section */}
      <div className="bg-[#141416] border border-white/5 shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold text-white/90 mb-4 flex items-center">
          <Key className="mr-2" size={20} />
          Two-Factor Authentication (TOTP)
        </h2>
        <p className="text-white/70 mb-6 text-sm">
          Add additional security to your account using two-factor authentication.
        </p>

        {is2FAEnabled ? (
          <div>
            <div className="flex items-center justify-between mb-4">
              <span className="text-green-600 font-medium">✓ 2FA is currently enabled</span>
              <button
                onClick={handleDisable2FA}
                className="px-4 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200"
              >
                Disable 2FA
              </button>
            </div>
            
            {recoveryCodes.length > 0 ? (
              <div className="mt-4 p-4 bg-[#1C1C1F] border rounded-lg">
                <h3 className="font-semibold text-white/90 mb-2">Recovery Codes</h3>
                <p className="text-sm text-white/70 mb-4">
                  Please save these recovery codes in a secure location. They will not be shown again.
                </p>
                <div className="grid grid-cols-2 gap-2 font-mono text-sm">
                  {recoveryCodes.map((code, index) => (
                    <div key={index} className="bg-[#141416] border border-white/5 p-2 border rounded text-center">
                      {code}
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <button
                onClick={handleRegenerateCodes}
                className="mt-4 text-[#6C2BD9] hover:underline text-sm font-medium"
              >
                Regenerate Recovery Codes
              </button>
            )}
          </div>
        ) : (
          <div>
            {!setupData ? (
              <button
                onClick={handleSetup2FA}
                className="px-4 py-2 bg-[#6C2BD9] text-white rounded-lg hover:bg-[#5b24b8]"
              >
                Enable 2FA
              </button>
            ) : (
              <div className="space-y-4 border p-4 rounded-lg bg-[#1C1C1F]">
                <h3 className="font-semibold text-white/90">Scan this QR Code</h3>
                <p className="text-sm text-white/70">
                  Scan the QR code below using an authenticator app like Google Authenticator or Authy.
                </p>
                <div className="flex justify-center bg-[#141416] border border-white/5 p-4 rounded border inline-block">
                  <img src={setupData.qr_code_svg} alt="2FA QR Code" className="w-48 h-48" />
                </div>
                <p className="text-sm text-white/70">Or enter this secret manually: <span className="font-mono bg-gray-200 px-2 py-1 rounded">{setupData.secret}</span></p>
                
                <div className="pt-4">
                  <label className="block text-sm font-medium text-white/80 mb-2">
                    Enter the 6-digit code to confirm
                  </label>
                  <div className="flex space-x-2">
                    <input
                      type="text"
                      className="border rounded px-3 py-2 focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9]"
                      placeholder="123456"
                      value={confirmCode}
                      onChange={(e) => setConfirmCode(e.target.value)}
                    />
                    <button
                      onClick={handleConfirm2FA}
                      className="px-4 py-2 bg-[#6C2BD9] text-white rounded hover:bg-[#5b24b8]"
                    >
                      Confirm
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Active Sessions Section */}
      <div className="bg-[#141416] border border-white/5 shadow rounded-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold text-white/90 flex items-center">
            <Monitor className="mr-2" size={20} />
            Active Sessions
          </h2>
          {sessions.length > 1 && (
            <button
              onClick={handleRevokeOtherSessions}
              className="text-sm px-3 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200"
            >
              Log out other devices
            </button>
          )}
        </div>
        <p className="text-white/70 mb-6 text-sm">
          These devices are currently logged into your account.
        </p>

        <div className="space-y-4">
          {loadingSessions ? (
            <p className="text-white/60">Loading sessions...</p>
          ) : (
            sessions.map(session => (
              <div key={session.id} className="flex items-center justify-between p-4 border rounded-lg bg-[#1C1C1F]">
                <div className="flex items-center space-x-4">
                  {session.platform?.toLowerCase().includes('ios') || session.platform?.toLowerCase().includes('android') ? (
                    <Smartphone className={session.is_current_device ? 'text-[#6C2BD9]' : 'text-white/50'} size={28} />
                  ) : (
                    <Monitor className={session.is_current_device ? 'text-[#6C2BD9]' : 'text-white/50'} size={28} />
                  )}
                  <div>
                    <div className="flex items-center">
                      <p className="font-medium text-white">{session.device_name || 'Unknown Device'}</p>
                      {session.is_current_device && (
                        <span className="ml-2 px-2 py-0.5 text-xs bg-green-100 text-green-700 rounded">Current</span>
                      )}
                    </div>
                    <p className="text-xs text-white/60">
                      IP: {session.ip_address || 'Unknown'} • Last Active: {new Date(session.last_active_at).toLocaleString()}
                    </p>
                  </div>
                </div>
                {!session.is_current_device && (
                  <button
                    onClick={() => handleRevokeSession(session.id)}
                    className="text-red-500 hover:text-red-700 p-2"
                    title="Log out device"
                  >
                    <Trash2 size={18} />
                  </button>
                )}
              </div>
            ))
          )}
        </div>
      </div>

      {/* Login Activity Section */}
      <div className="bg-[#141416] border border-white/5 shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold text-white/90 mb-4 flex items-center">
          <History className="mr-2" size={20} />
          Login Activity
        </h2>
        <p className="text-white/70 mb-6 text-sm">
          Recent authentication events for your account.
        </p>

        <div className="space-y-3">
          {loadingActivities ? (
            <p className="text-white/60">Loading activity...</p>
          ) : activities.length === 0 ? (
            <p className="text-white/60 italic">No recent activity.</p>
          ) : (
            activities.map(activity => (
              <div key={activity.id} className="flex items-center p-3 border-b last:border-0">
                <div className={`w-2 h-2 rounded-full mr-3 ${activity.event_type.includes('success') ? 'bg-green-500/100' : activity.event_type.includes('failed') ? 'bg-red-500/100' : 'bg-gray-400'}`}></div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-white capitalize">
                    {activity.event_type.replace(/_/g, ' ')}
                  </p>
                  <p className="text-xs text-white/60">
                    {activity.platform || 'Unknown OS'} • {activity.ip_address || 'Unknown IP'}
                  </p>
                </div>
                <div className="text-xs text-white/50">
                  {new Date(activity.created_at).toLocaleString()}
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};

export default Profile;
