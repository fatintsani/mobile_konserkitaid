import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { LogIn, AlertCircle } from 'lucide-react';
import { useGoogleLogin } from '@react-oauth/google';
import { useMsal } from '@azure/msal-react';
import { startAuthentication } from '@simplewebauthn/browser';
import api from '../api/axios';
import { Fingerprint } from 'lucide-react';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  
  const [requires2FA, setRequires2FA] = useState(false);
  const [tempToken, setTempToken] = useState(null);
  const [twoFactorCode, setTwoFactorCode] = useState('');
  const [isRecoveryCode, setIsRecoveryCode] = useState(false);

  const { login, socialLogin, passkeyLogin, verify2FA } = useAuth();
  const navigate = useNavigate();
  const { instance } = useMsal();

  const handleSocialSuccess = async (accessToken, provider) => {
    setError('');
    setIsLoading(true);
    const result = await socialLogin(accessToken, provider);
    if (result.requires2FA) {
      setRequires2FA(true);
      setTempToken(result.temporaryToken);
      setIsLoading(false);
    } else if (result.success) {
      navigate('/');
    } else {
      setError(result.message);
      setIsLoading(false);
    }
  };

  const loginWithGoogle = useGoogleLogin({
    onSuccess: (tokenResponse) => handleSocialSuccess(tokenResponse.access_token, 'google'),
    onError: () => setError('Google Login Failed'),
  });

  const loginWithMicrosoft = async () => {
    try {
      const response = await instance.loginPopup({
        scopes: ["user.read"]
      });
      if (response.accessToken) {
        handleSocialSuccess(response.accessToken, 'microsoft');
      }
    } catch (e) {
      setError('Microsoft Login Failed');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);
    
    const result = await login(email, password);
    
    if (result.requires2FA) {
      setRequires2FA(true);
      setTempToken(result.temporaryToken);
      setIsLoading(false);
    } else if (result.success) {
      navigate('/');
    } else {
      setError(result.message);
      setIsLoading(false);
    }
  };

  const handlePasskeyLogin = async () => {
    setError('');
    setIsLoading(true);
    try {
      const optionsRes = await api.post('/passkeys/login/options', { email });
      const options = optionsRes.data;

      const asseResp = await startAuthentication(options);

      const result = await passkeyLogin({
        ...asseResp,
        email
      });

      if (result.requires2FA) {
        setRequires2FA(true);
        setTempToken(result.temporaryToken);
        setIsLoading(false);
      } else if (result.success) {
        navigate('/');
      } else {
        setError(result.message);
        setIsLoading(false);
      }
    } catch (err) {
      console.error(err);
      setError(err.message || 'Passkey login failed');
      setIsLoading(false);
    }
  };

  const handle2FASubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    const result = await verify2FA(tempToken, twoFactorCode, isRecoveryCode);

    if (result.success) {
      navigate('/');
    } else {
      setError(result.message);
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#1C1C1F] py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8 bg-[#141416] border border-white/5 p-8 rounded-xl shadow-lg border border-white/5">
        <div>
          <h2 className="mt-2 text-center text-3xl font-extrabold text-white">
            <span className="text-[#6C2BD9]">KonserKita</span> Admin
          </h2>
          <p className="mt-2 text-center text-sm text-white/70">
            Sign in to access the dashboard
          </p>
        </div>
        
        {error && (
          <div className="bg-red-500/10 border-l-4 border-red-500 p-4 mb-4">
            <div className="flex items-center">
              <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
              <p className="text-sm text-red-700">{error}</p>
            </div>
          </div>
        )}

        {!requires2FA ? (
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="rounded-md shadow-sm space-y-4">
            <div>
              <label htmlFor="email-address" className="sr-only">Email address</label>
              <input
                id="email-address"
                name="email"
                type="email"
                required
                className="appearance-none relative block w-full px-3 py-3 border border-white/20 placeholder-gray-500 text-white rounded-lg focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9] focus:z-10 sm:text-sm"
                placeholder="Admin Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div>
              <label htmlFor="password" className="sr-only">Password</label>
              <input
                id="password"
                name="password"
                type="password"
                required
                className="appearance-none relative block w-full px-3 py-3 border border-white/20 placeholder-gray-500 text-white rounded-lg focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9] focus:z-10 sm:text-sm"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={isLoading}
              className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-lg text-white bg-[#6C2BD9] hover:bg-[#5b24b8] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#6C2BD9] disabled:opacity-70 transition-colors"
            >
              {isLoading ? (
                'Signing in...'
              ) : (
                <>
                  <LogIn className="absolute left-0 inset-y-0 flex items-center pl-3 h-5 w-5 text-[#5b24b8] group-hover:text-white" />
                  Sign in
                </>
              )}
            </button>
          </div>

          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-white/20"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-[#141416] border border-white/5 text-white/60">Or continue with</span>
              </div>
            </div>

            <div className="mt-6 grid grid-cols-2 gap-3">
              <div>
                <button
                  type="button"
                  onClick={() => loginWithGoogle()}
                  disabled={isLoading}
                  className="w-full inline-flex justify-center py-2 px-4 border border-white/20 rounded-md shadow-sm bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-70"
                >
                  <span className="sr-only">Sign in with Google</span>
                  <img className="h-5 w-5" src="https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg" alt="Google" />
                </button>
              </div>

              <div>
                <button
                  type="button"
                  onClick={loginWithMicrosoft}
                  disabled={isLoading}
                  className="w-full inline-flex justify-center py-2 px-4 border border-white/20 rounded-md shadow-sm bg-[#141416] border border-white/5 text-sm font-medium text-white/60 hover:bg-[#1C1C1F] disabled:opacity-70"
                >
                  <span className="sr-only">Sign in with Microsoft</span>
                  <img className="h-5 w-5" src="https://upload.wikimedia.org/wikipedia/commons/4/44/Microsoft_logo.svg" alt="Microsoft" />
                </button>
              </div>
            </div>

            <div className="mt-4">
              <button
                type="button"
                onClick={handlePasskeyLogin}
                disabled={isLoading}
                className="w-full inline-flex justify-center items-center py-2 px-4 border border-white/20 rounded-md shadow-sm bg-[#141416] border border-white/5 text-sm font-medium text-white/80 hover:bg-[#1C1C1F] disabled:opacity-70"
              >
                <Fingerprint className="h-5 w-5 mr-2 text-[#6C2BD9]" />
                Sign in with Passkey
              </button>
            </div>
          </div>
        </form>
        ) : (
        <form className="mt-8 space-y-6" onSubmit={handle2FASubmit}>
          <div className="rounded-md shadow-sm space-y-4">
            <div>
              <label htmlFor="2fa-code" className="sr-only">
                {isRecoveryCode ? 'Recovery Code' : 'Authentication Code'}
              </label>
              <input
                id="2fa-code"
                name="code"
                type="text"
                required
                className="appearance-none relative block w-full px-3 py-3 border border-white/20 placeholder-gray-500 text-white rounded-lg focus:outline-none focus:ring-[#6C2BD9] focus:border-[#6C2BD9] focus:z-10 sm:text-sm"
                placeholder={isRecoveryCode ? "Enter Recovery Code" : "Enter 6-digit code"}
                value={twoFactorCode}
                onChange={(e) => setTwoFactorCode(e.target.value)}
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={isLoading || !twoFactorCode}
              className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-lg text-white bg-[#6C2BD9] hover:bg-[#5b24b8] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#6C2BD9] disabled:opacity-70 transition-colors"
            >
              {isLoading ? 'Verifying...' : 'Verify Code'}
            </button>
          </div>

          <div className="mt-4 text-center">
            <button
              type="button"
              onClick={() => setIsRecoveryCode(!isRecoveryCode)}
              className="text-sm text-[#6C2BD9] hover:text-[#5b24b8]"
            >
              {isRecoveryCode ? 'Use Authenticator App' : 'Use Recovery Code'}
            </button>
          </div>
        </form>
        )}
      </div>
    </div>
  );
};

export default Login;
