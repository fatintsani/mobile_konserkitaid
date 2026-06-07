import React from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
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
  Share2
} from 'lucide-react';

const AdminLayout = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const navItems = [
    { name: 'Dashboard', path: '/', icon: <LayoutDashboard size={20} /> },
    { name: 'Events', path: '/events', icon: <CalendarDays size={20} /> },
    { name: 'Organizers', path: '/organizers', icon: <Briefcase size={20} /> },
    { name: 'Users', path: '/users', icon: <Users size={20} /> },
    { name: 'Transactions', path: '/transactions', icon: <CreditCard size={20} /> },
    { name: 'Refunds', path: '/refunds', icon: <RefreshCcw size={20} /> },
    { name: 'Reviews', path: '/reviews', icon: <Star size={20} /> },
    { name: 'Payouts', path: '/payouts', icon: <Wallet size={20} /> },
    { name: 'Reports', path: '/reports', icon: <BarChart3 size={20} /> },
    { name: 'Broadcast', path: '/broadcast', icon: <Radio size={20} /> },
    { name: 'Referrals', path: '/referrals', icon: <Share2 size={20} /> },
  ];

  const contentItems = [
    { name: 'Venues', path: '/venues', icon: <MapPin size={20} /> },
    { name: 'Banners', path: '/banners', icon: <Image size={20} /> },
    { name: 'Promo Codes', path: '/promos', icon: <Tag size={20} /> },
    { name: 'Categories', path: '/categories', icon: <FolderTree size={20} /> },
  ];

  return (
    <div className="flex h-screen bg-[#F8F7FC] text-gray-800 font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200 flex flex-col hidden md:flex">
        <div className="h-16 flex items-center px-6 border-b border-gray-200">
          <span className="text-2xl font-bold text-[#6C2BD9]">KonserKita</span>
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
                      ? 'bg-[#6C2BD9] text-white'
                      : 'text-gray-600 hover:bg-gray-100'
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
                      ? 'bg-[#6C2BD9] text-white'
                      : 'text-gray-600 hover:bg-gray-100'
                  }`
                }
              >
                <span className="mr-3">{item.icon}</span>
                {item.name}
              </NavLink>
            ))}
          </nav>
        </div>
        <div className="p-4 border-t border-gray-200">
          <button
            onClick={handleLogout}
            className="flex items-center w-full px-3 py-2 text-sm font-medium text-red-600 rounded-lg hover:bg-red-50 transition-colors"
          >
            <LogOut size={20} className="mr-3" />
            Logout
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Topbar */}
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-4 sm:px-6">
          <div className="flex items-center md:hidden">
            <button className="text-gray-500 hover:text-gray-700">
              <Menu size={24} />
            </button>
            <span className="ml-3 text-xl font-bold text-[#6C2BD9]">KonserKita</span>
          </div>
          <div className="hidden md:block"></div>
          <div className="flex items-center">
            <div className="flex items-center space-x-3">
              <div className="flex flex-col text-right">
                <span className="text-sm font-medium">{user?.name}</span>
                <span className="text-xs text-gray-500">{user?.role}</span>
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
