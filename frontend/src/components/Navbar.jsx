import React, { useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { 
  BookOpen, Bell, LogOut, Check,
  ShieldCheck, Tractor, Briefcase
} from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { distributionsApi } from '../services/api';

export default function Navbar() {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState([]);
  const [showNotifs, setShowNotifs] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const notifRef = useRef(null);

  const fetchNotifs = async () => {
    try {
      const res = await distributionsApi.getNotifications();
      setNotifications(res.data);
      setUnreadCount(res.data.filter((n) => !n.is_read).length);
    } catch (e) {
      // Ignore notif fetch errors
    }
  };

  useEffect(() => {
    fetchNotifs();
    const interval = setInterval(fetchNotifs, 15000);
    return () => clearInterval(interval);
  }, []);

  // Close notification dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (notifRef.current && !notifRef.current.contains(event.target)) {
        setShowNotifs(false);
      }
    };
    if (showNotifs) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [showNotifs]);

  const handleMarkRead = async (id) => {
    try {
      await distributionsApi.markRead(id);
      fetchNotifs();
    } catch (e) {
      //
    }
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const getRoleBadge = (role) => {
    switch (role) {
      case 'ADMIN':
        return (
          <span className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-rose-50 text-rose-600 border border-rose-200 shadow-2xs">
            <ShieldCheck className="w-3.5 h-3.5 stroke-[2.2]" /> Admin Dinas
          </span>
        );
      case 'PPL':
        return (
          <span className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200 shadow-2xs">
            <Briefcase className="w-3.5 h-3.5 stroke-[2.2]" /> Petugas PPL
          </span>
        );
      case 'PETANI':
        return (
          <span className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-300 shadow-2xs">
            <Check className="w-3.5 h-3.5 text-emerald-600 stroke-[2.5]" /> Petani Terdaftar
          </span>
        );
      default:
        return (
          <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-700">
            {role}
          </span>
        );
    }
  };

  return (
    <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200/80 shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand */}
        <div className="flex items-center gap-3">
          <Link to="/" className="flex items-center gap-2.5 group">
            <div className="w-9 h-9 rounded-xl bg-emerald-700 flex items-center justify-center text-white shadow-xs group-hover:scale-105 transition-transform shrink-0">
              <BookOpen className="w-5 h-5 stroke-[2.2]" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-base sm:text-lg font-black tracking-tight text-slate-900 font-display">
                  E-PUPUK
                </span>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 uppercase tracking-wider">
                  KABUPATEN MOJOKERTO
                </span>
              </div>
              <p className="text-[11px] text-slate-400 font-medium -mt-0.5 hidden sm:block">
                Sistem Subsidi & Distribusi Pupuk
              </p>
            </div>
          </Link>
        </div>

        {/* Right Menu */}
        <div className="flex items-center gap-3 sm:gap-4">
          {/* Role badge */}
          {user && getRoleBadge(user.role)}

          {/* Notification Bell */}
          <div className="relative" ref={notifRef}>
            <button
              onClick={() => setShowNotifs(!showNotifs)}
              className="relative p-2 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors"
              title="Notifikasi"
            >
              <Bell className="w-5 h-5" />
              {unreadCount > 0 && (
                <span className="absolute top-1.5 right-1.5 w-4 h-4 bg-rose-600 text-white text-[10px] font-bold rounded-full flex items-center justify-center ring-2 ring-white animate-pulse">
                  {unreadCount}
                </span>
              )}
            </button>

            {/* Notifications Dropdown */}
            {showNotifs && (
              <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden z-50 animate-in fade-in slide-in-from-top-2 duration-150">
                <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50">
                  <h4 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    Notifikasi Sistem
                  </h4>
                  <span className="text-[11px] text-slate-500 font-medium">
                    {unreadCount} belum dibaca
                  </span>
                </div>

                <div className="max-h-80 overflow-y-auto divide-y divide-slate-100">
                  {notifications.length === 0 ? (
                    <div className="py-8 text-center text-xs text-slate-400">
                      Tidak ada notifikasi baru
                    </div>
                  ) : (
                    notifications.map((n) => (
                      <div
                        key={n.id}
                        className={`p-3.5 transition-colors ${
                          n.is_read ? 'bg-white' : 'bg-emerald-50/40'
                        } hover:bg-slate-50 flex items-start justify-between gap-2`}
                      >
                        <div className="flex-1">
                          <p className="text-xs font-bold text-slate-800 leading-tight">
                            {n.judul}
                          </p>
                          <p className="text-[11px] text-slate-600 mt-1 leading-relaxed">
                            {n.pesan}
                          </p>
                          <span className="text-[10px] text-slate-400 mt-1.5 block">
                            {new Date(n.created_at).toLocaleString('id-ID', {
                              dateStyle: 'short',
                              timeStyle: 'short',
                            })}
                          </span>
                        </div>
                        {!n.is_read && (
                          <button
                            onClick={() => handleMarkRead(n.id)}
                            className="p-1 rounded text-slate-400 hover:text-emerald-600"
                            title="Tandai sudah dibaca"
                          >
                            <Check className="w-3.5 h-3.5" />
                          </button>
                        )}
                      </div>
                    ))
                  )}
                </div>
              </div>
            )}
          </div>

          {/* User Profile & Logout */}
          <div className="flex items-center gap-3 pl-2">
            <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center text-xs font-bold shrink-0">
              {(user?.nama || user?.username || 'B').charAt(0).toUpperCase()}
            </div>
            <div className="text-left hidden sm:block leading-tight">
              <p className="text-xs font-bold text-slate-800 truncate max-w-[140px]">
                {user?.nama || 'Budi Santoso'}
              </p>
              <p className="text-[10px] text-slate-400 font-mono">
                @{user?.username || 'petani_budi'}
              </p>
            </div>
            <button
              onClick={handleLogout}
              className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 transition-colors ml-1"
              title="Keluar"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
