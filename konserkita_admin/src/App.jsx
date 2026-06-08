import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import AdminLayout from './layouts/AdminLayout';

// Pages
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Events from './pages/Events';
import Users from './pages/Users';
import Organizers from './pages/Organizers';
import Transactions from './pages/Transactions';
import Referrals from "./pages/Referrals";
import Recommendations from "./pages/Recommendations";
import OrganizerReviews from "./pages/OrganizerReviews";
import Reports from './pages/Reports';
import Banners from './pages/Banners';
import PromoCodes from './pages/PromoCodes';
import Categories from './pages/Categories';
import Refunds from './pages/Refunds';
import Payouts from './pages/Payouts';
import Venues from './pages/Venues';
import VenueDetail from './pages/VenueDetail';
import Reviews from './pages/Reviews';
import BroadcastNotification from './pages/BroadcastNotification';
import SubscriptionPlans from './pages/SubscriptionPlans';
import Profile from './pages/Profile';
import SecurityDashboard from './pages/SecurityDashboard';
import AccountRecoveryDashboard from './pages/AccountRecoveryDashboard';

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route element={<ProtectedRoute />}>
            <Route element={<AdminLayout />}>
              <Route path="/" element={<Dashboard />} />
              <Route path="/profile" element={<Profile />} />
              <Route path="/events" element={<Events />} />
              <Route path="users" element={<Users />} />
              <Route path="recommendations" element={<Recommendations />} />
              <Route path="/organizers" element={<Organizers />} />
              <Route path="/organizer-reviews" element={<OrganizerReviews />} />
              <Route path="/transactions" element={<Transactions />} />
              <Route path="/reports" element={<Reports />} />
              <Route path="/banners" element={<Banners />} />
              <Route path="/promos" element={<PromoCodes />} />
              <Route path="/categories" element={<Categories />} />
              <Route path="/refunds" element={<Refunds />} />
              <Route path="/payouts" element={<Payouts />} />
              <Route path="/venues" element={<Venues />} />
              <Route path="/venues/:id" element={<VenueDetail />} />
              <Route path="/reviews" element={<Reviews />} />
              <Route path="/broadcast" element={<BroadcastNotification />} />
              <Route path="/referrals" element={<Referrals />} />
              <Route path="/subscription-plans" element={<SubscriptionPlans />} />
              <Route path="/security" element={<SecurityDashboard />} />
              <Route path="/account-recovery" element={<AccountRecoveryDashboard />} />
            </Route>
          </Route>
          
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
