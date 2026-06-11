import React from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../contexts/AuthContext';
import { 
  LayoutDashboard, 
  CalendarDays, 
  Users, 
  Briefcase, 
  CreditCard, 
  Ticket, 
  BarChart3, 
  LogOut,
  Menu,
  Image,
  Tag,
  FolderTree,
  RefreshCcw,
  Wallet,
  MapPin,
  Star,
  Radio,
  Share2,
  Sparkles,
  ShieldAlert,
  Unlock,
  FileText
} from 'lucide-react';

const AdminLayout = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { t, i18n } = useTranslation();

  const changeLanguage = (e) => {
    i18n.changeLanguage(e.target.value);
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const navItems = [
    { name: t('sidebar.dashboard'), path: '/', icon: <LayoutDashboard size={20} /> },
    { name: t('sidebar.events'), path: '/events', icon: <CalendarDays size={20} /> },
    { name: t('sidebar.organizers'), path: '/organizers', icon: <Briefcase size={20} /> },
    { name: t('sidebar.users'), path: '/users', icon: <Users size={20} /> },
    { name: t('sidebar.transactions'), path: '/transactions', icon: <CreditCard size={20} /> },
    { name: t('sidebar.refunds'), path: '/refunds', icon: <RefreshCcw size={20} /> },
    { name: t('sidebar.reviews'), path: '/reviews', icon: <Star size={20} /> },
    { name: t('sidebar.organizer_reviews'), path: '/organizer-reviews', icon: <Star size={20} /> },
    { name: t('sidebar.payouts'), path: '/payouts', icon: <Wallet size={20} /> },
    { name: t('sidebar.reports'), path: '/reports', icon: <BarChart3 size={20} /> },
    { name: t('sidebar.broadcast'), path: '/broadcast', icon: <Radio size={20} /> },
    { name: t('sidebar.recommendations'), path: '/recommendations', icon: <Sparkles size={20} /> },
    { name: t('sidebar.referrals'), path: '/referrals', icon: <Share2 size={20} /> },
    { name: t('sidebar.subscriptions'), path: '/subscription-plans', icon: <CreditCard size={20} /> },
    { name: t('sidebar.security'), path: '/security', icon: <ShieldAlert size={20} /> },
    { name: t('sidebar.account_recovery'), path: '/account-recovery', icon: <Unlock size={20} /> },
    { name: t('sidebar.audit_trail'), path: '/audit-trail', icon: <FileText size={20} /> },
  ];

  const contentItems = [
    { name: t('sidebar.venues'), path: '/venues', icon: <MapPin size={20} /> },
    { name: t('sidebar.banners'), path: '/banners', icon: <Image size={20} /> },
    { name: t('sidebar.categories'), path: '/categories', icon: <FolderTree size={20} /> },
  ];

  return (
    <div className="flex h-screen bg-[#0A0A0B] text-gray-300 font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-[#141416] border-r border-white/10 flex flex-col hidden md:flex">
        <div className="h-16 flex items-center px-6 border-b border-white/10">
          <span className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-[#8B5CF6] to-[#4B9FFF]">KonserKita</span>
        </div>
        <div className="flex-1 overflow-y-auto py-4">
          <nav className="space-y-1 px-3">
            {navItems.map((item) => (
              <NavLink
                key={item.name}
                to={item.path}
                className={({ isActive }) =>
                  `flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-[#6C2BD9] text-white shadow-[0_0_15px_rgba(108,43,217,0.3)]'
                      : 'text-gray-400 hover:bg-white/5 hover:text-white'
                  }`
                }
              >
                <span className="mr-3">{item.icon}</span>
                {item.name}
              </NavLink>
            ))}

            <div className="pt-4 pb-2">
              <p className="px-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">
                Content
              </p>
            </div>

            {contentItems.map((item) => (
              <NavLink
                key={item.name}
                to={item.path}
                className={({ isActive }) =>
                  `flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-[#6C2BD9] text-white shadow-[0_0_15px_rgba(108,43,217,0.3)]'
                      : 'text-gray-400 hover:bg-white/5 hover:text-white'
                  }`
                }
              >
                <span className="mr-3">{item.icon}</span>
                {item.name}
              </NavLink>
            ))}
          </nav>
        </div>
        <div className="p-4 border-t border-white/10">
          <button
            onClick={handleLogout}
            className="flex items-center w-full px-3 py-2 text-sm font-medium text-red-400 rounded-lg hover:bg-red-500/10 hover:text-red-300 transition-colors"
          >
            <LogOut size={20} className="mr-3" />
            {t('topbar.logout')}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Topbar */}
        <header className="h-16 bg-[#141416] border-b border-white/10 flex items-center justify-between px-4 sm:px-6">
          <div className="flex items-center md:hidden">
            <button className="text-gray-400 hover:text-white">
              <Menu size={24} />
            </button>
            <span className="ml-3 text-xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-[#8B5CF6] to-[#4B9FFF]">KonserKita</span>
          </div>
          <div className="hidden md:block"></div>
          <div className="flex items-center space-x-6">
            <select
              onChange={changeLanguage}
              defaultValue={i18n.language}
              className="text-sm bg-[#1C1C1F] border border-white/10 text-white rounded-md focus:ring-[#6C2BD9] focus:border-[#6C2BD9]"
            >
              <option value="id">Indonesia</option>
              <option value="en">English</option>
            </select>
            <div className="flex items-center space-x-3 cursor-pointer" onClick={() => navigate('/profile')}>
              <div className="flex flex-col text-right hover:text-white transition-colors">
                <span className="text-sm font-medium text-white">{user?.name}</span>
                <span className="text-xs text-gray-400">{user?.role}</span>
              </div>
              <div className="h-8 w-8 rounded-full bg-[#6C2BD9] flex items-center justify-center text-white font-bold">
                {user?.name?.charAt(0).toUpperCase()}
              </div>
            </div>
          </div>
        </header>

        {/* Main Area */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default AdminLayout;
