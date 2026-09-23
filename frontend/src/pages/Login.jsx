import React, { useState, useEffect } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { 
  Sprout, 
  Lock, 
  User, 
  ShieldCheck, 
  Tractor, 
  Briefcase, 
  ArrowRight, 
  Building2, 
  ArrowLeft
} from 'lucide-react';
import { useAuthStore } from '../store/authStore';

const PORTAL_CONFIG = {
  petani: {
    id: 'petani',
    label: 'Petani & Poktan',
    roleTag: 'LAYANAN PETANI',
    title: 'Selamat Datang',
    subtitle: 'Masuk untuk mengajukan subsidi & cek alokasi pupuk Anda.',
    image: '/logingambar.jpg',
    imageTitle: 'Penyaluran Pupuk Bersubsidi',
    imageSubtitle: 'Dinas Pertanian dan Ketahanan Pangan Kab. Mojokerto',
    buttonColor: 'bg-[#059669] hover:bg-[#047857] text-white shadow-[#059669]/25',
    activeTab: 'bg-[#059669] text-white shadow-sm',
    badgeColor: 'bg-[#ecfdf5] text-[#059669] border-[#a7f3d0]/70',
    icon: Tractor,
    demoAccounts: [
      {
        username: 'petani_budi',
        pass: 'petani123',
        name: 'Petani Budi',
        desc: 'Mojosari (Komoditas Padi)',
        icon: Tractor
      },
      {
        username: 'petani_siti',
        pass: 'petani123',
        name: 'Petani Siti',
        desc: 'Trowulan (Komoditas Jagung)',
        icon: Tractor
      }
    ],
    showRegister: true
  },
  admin: {
    id: 'admin',
    label: 'Admin Dinas',
    roleTag: 'DINAS PERTANIAN',
    title: 'Portal Admin Dinas',
    subtitle: 'Masuk untuk verifikasi berkas, persetujuan kuota & audit.',
    image: '/admin.jpg',
    imageTitle: 'Otoritas & Pengawasan Pupuk',
    imageSubtitle: 'Sistem Terpadu Verifikasi & Alokasi Kuota',
    buttonColor: 'bg-[#0f172a] hover:bg-[#1e293b] text-white shadow-slate-900/20',
    activeTab: 'bg-[#0f172a] text-white shadow-sm',
    badgeColor: 'bg-[#ecfdf5] text-[#059669] border-[#a7f3d0]/70',
    icon: Building2,
    demoAccounts: [
      {
        username: 'admin',
        pass: 'admin123',
        name: 'Admin Dinas',
        desc: 'Verifikasi Berkas & Final Appr...',
        icon: ShieldCheck
      }
    ],
    showRegister: false
  },
  ppl: {
    id: 'ppl',
    label: 'Petugas PPL',
    roleTag: 'PETUGAS LAPANGAN',
    title: 'Portal Petugas PPL',
    subtitle: 'Masuk untuk survei lahan fisik, geotagging GPS & upload laporan.',
    image: '/ppl.jpg',
    imageTitle: 'Survei Faktual Lapangan',
    imageSubtitle: 'Validasi Batas Sawah & Tanaman Petani',
    buttonColor: 'bg-[#1d63ed] hover:bg-[#1e40af] text-white shadow-blue-600/25',
    activeTab: 'bg-[#1d63ed] text-white shadow-sm',
    badgeColor: 'bg-[#ecfdf5] text-[#059669] border-[#a7f3d0]/70',
    icon: Briefcase,
    demoAccounts: [
      {
        username: 'ppl_ahmad',
        pass: 'ppl123',
        name: 'PPL Ahmad',
        desc: 'Petugas Survei Fisik Mojokerto',
        icon: Briefcase
      }
    ],
    showRegister: false
  }
};

export default function Login() {
  const { portalRole } = useParams();
  const navigate = useNavigate();
  const { login } = useAuthStore();

  const [activePortal, setActivePortal] = useState('petani');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (portalRole && PORTAL_CONFIG[portalRole.toLowerCase()]) {
      setActivePortal(portalRole.toLowerCase());
    }
  }, [portalRole]);

  const handlePortalSwitch = (portalKey) => {
    setActivePortal(portalKey);
    setError('');
    setUsername('');
    setPassword('');
    navigate(`/login/${portalKey}`);
  };

  const currentConfig = PORTAL_CONFIG[activePortal] || PORTAL_CONFIG.petani;

  const handleLogin = async (e) => {
    e?.preventDefault();
    if (!username || !password) {
      setError('Username dan kata sandi wajib diisi');
      return;
    }
    setError('');
    setLoading(true);

    const res = await login(username, password);
    setLoading(false);

    if (res.success) {
      if (res.user.role === 'ADMIN') {
        navigate('/admin');
      } else if (res.user.role === 'PPL') {
        navigate('/ppl');
      } else {
        navigate('/petani');
      }
    } else {
      setError(res.error);
    }
  };

  const handleQuickLogin = async (u, p) => {
    setUsername(u);
    setPassword(p);
    setError('');
    setLoading(true);

    const res = await login(u, p);
    setLoading(false);

    if (res.success) {
      if (res.user.role === 'ADMIN') {
        navigate('/admin');
      } else if (res.user.role === 'PPL') {
        navigate('/ppl');
      } else {
        navigate('/petani');
      }
    } else {
      setError(res.error);
    }
  };

  return (
    <div className="min-h-screen bg-[#f8fafc] font-sans text-slate-800 antialiased flex flex-col justify-between selection:bg-emerald-100 selection:text-emerald-800">
      
      {/* 1. Navigation Bar */}
      <header className="bg-white border-b border-slate-200/80 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16 sm:h-20">
            
            <Link to="/" className="flex items-center gap-3 group">
              <div className="w-10 h-10 rounded-xl bg-[#059669] flex items-center justify-center text-white shadow-md shadow-emerald-600/20 group-hover:scale-105 transition-transform">
                <Sprout className="w-6 h-6 stroke-[2.2]" />
              </div>
              <div>
                <h1 className="text-xl font-bold tracking-tight text-slate-900 leading-none">
                  E-PUPUK
                </h1>
                <p className="text-[11px] text-slate-500 font-medium mt-0.5">
                  Kabupaten Mojokerto
                </p>
              </div>
            </Link>

            <Link 
              to="/"
              className="text-xs sm:text-sm font-semibold text-slate-600 hover:text-emerald-600 flex items-center gap-1.5 transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Kembali ke Beranda</span>
            </Link>

          </div>
        </div>
      </header>

      {/* 2. Main Login Container */}
      <main className="flex-1 flex items-center justify-center p-3 sm:p-6 lg:p-8">
        <div className="w-full max-w-5xl bg-white rounded-3xl border border-slate-200/80 shadow-xl overflow-hidden grid grid-cols-1 md:grid-cols-12 min-h-[540px]">
          
          {/* Left Column: Form & Role Switcher */}
          <div className="md:col-span-6 lg:col-span-6 p-6 sm:p-8 flex flex-col justify-between">
            <div>
              
              {/* Role Switcher Tabs */}
              <div className="mb-5">
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">
                  PILIH PORTAL MASUK:
                </p>
                <div className="grid grid-cols-3 gap-1.5 p-1 bg-[#f1f5f9] rounded-xl border border-slate-200/60">
                  {Object.values(PORTAL_CONFIG).map((p) => {
                    const Icon = p.icon;
                    const isActive = activePortal === p.id;
                    return (
                      <button
                        key={p.id}
                        type="button"
                        onClick={() => handlePortalSwitch(p.id)}
                        className={`flex items-center justify-center gap-1.5 py-2 px-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                          isActive 
                            ? p.activeTab 
                            : 'text-slate-600 hover:text-slate-900 hover:bg-white/80'
                        }`}
                      >
                        <Icon className="w-3.5 h-3.5 shrink-0" />
                        <span className="truncate text-[11px]">{p.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Title & Subtitle */}
              <div className="mb-5">
                <div className="inline-block px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider border mb-2 bg-[#ecfdf5] text-[#059669] border-[#a7f3d0]/70">
                  {currentConfig.roleTag}
                </div>
                <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
                  {currentConfig.title}
                </h2>
                <p className="text-xs sm:text-sm text-slate-500 mt-1">
                  {currentConfig.subtitle}
                </p>
              </div>

              {/* Error Message */}
              {error && (
                <div className="mb-4 p-2.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-rose-500 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              {/* Form Inputs */}
              <form onSubmit={handleLogin} className="space-y-3.5">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Username
                  </label>
                  <div className="relative">
                    <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <input
                      type="text"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      placeholder="Masukkan username Anda"
                      className="w-full pl-10 pr-4 py-2.5 bg-[#f8fafc] border border-slate-200/80 focus:bg-white focus:border-[#059669] focus:ring-2 focus:ring-[#059669]/20 rounded-xl text-slate-900 text-xs placeholder:text-slate-400 outline-none transition-all"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Kata Sandi
                  </label>
                  <div className="relative">
                    <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Masukkan kata sandi"
                      className="w-full pl-10 pr-4 py-2.5 bg-[#f8fafc] border border-slate-200/80 focus:bg-white focus:border-[#059669] focus:ring-2 focus:ring-[#059669]/20 rounded-xl text-slate-900 text-xs placeholder:text-slate-400 outline-none transition-all"
                      required
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className={`w-full py-3 px-4 ${currentConfig.buttonColor} font-bold text-xs rounded-xl shadow-md flex items-center justify-center gap-2 transition-all duration-200 disabled:opacity-50 cursor-pointer mt-1`}
                >
                  {loading ? (
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <>
                      <span>Masuk Sekarang</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </button>
              </form>

              {/* Link to Register (If Petani) or Official note */}
              {currentConfig.showRegister ? (
                <p className="mt-3.5 text-center text-xs text-slate-500">
                  Belum mempunyai akun?{' '}
                  <Link
                    to="/register"
                    className="text-[#059669] font-bold hover:underline"
                  >
                    Buat disini
                  </Link>
                </p>
              ) : (
                <p className="mt-3.5 text-center text-[11px] text-slate-400">
                  Akses khusus petugas resmi terdaftar Dinas Pertanian.
                </p>
              )}

            </div>

            {/* Quick Demo Logins Section */}
            <div className="mt-6 pt-4 border-t border-slate-100">
              <div className="flex items-center justify-between mb-2">
                <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">
                  ⚡ AKSES CEPAT DEMO ({currentConfig.label.toUpperCase()})
                </p>
                <span className="text-[10px] text-[#059669] bg-[#ecfdf5] border border-[#a7f3d0]/60 px-2 py-0.5 rounded font-bold">
                  1-Klik Masuk
                </span>
              </div>

              <div className={`grid ${currentConfig.demoAccounts.length > 1 ? 'grid-cols-1 sm:grid-cols-2' : 'grid-cols-1'} gap-2`}>
                {currentConfig.demoAccounts.map((acc, idx) => {
                  const AccIcon = acc.icon;
                  return (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => handleQuickLogin(acc.username, acc.pass)}
                      className="p-2 text-left rounded-xl bg-slate-50/80 hover:bg-emerald-50/60 border border-slate-200/80 hover:border-emerald-300 transition-all group cursor-pointer flex items-center gap-2.5"
                    >
                      <div className="w-7 h-7 rounded-lg bg-[#ecfdf5] border border-[#a7f3d0]/70 text-[#059669] flex items-center justify-center shrink-0 shadow-2xs group-hover:bg-[#059669] group-hover:text-white transition-colors">
                        <AccIcon className="w-3.5 h-3.5" />
                      </div>
                      <div className="min-w-0">
                        <p className="text-xs font-bold text-slate-800 group-hover:text-[#059669] truncate">
                          {acc.name}
                        </p>
                        <p className="text-[10px] text-slate-500 truncate">
                          {acc.desc}
                        </p>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

          </div>

          {/* Right Column: Image Banner with Inset Frame */}
          <div className="hidden md:block md:col-span-6 lg:col-span-6 relative p-4 sm:p-5 bg-slate-50/40">
            <div className="relative w-full h-full min-h-[480px] rounded-2xl overflow-hidden shadow-inner flex flex-col justify-end p-5">
              
              <img 
                src={currentConfig.image} 
                alt="E-PUPUK Kabupaten Mojokerto" 
                className="absolute inset-0 w-full h-full object-cover"
              />
              
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-black/20" />

              {/* Overlay Info Card at bottom */}
              <div className="relative z-10 bg-white/95 backdrop-blur-md p-3.5 sm:p-4 rounded-2xl shadow-xl border border-white/60">
                <div className="flex items-center gap-2.5 mb-1">
                  <div className="w-8 h-8 rounded-xl bg-[#059669] text-white flex items-center justify-center font-bold shadow-sm shadow-emerald-600/30 shrink-0">
                    <Sprout className="w-4 h-4" />
                  </div>
                  <div className="min-w-0">
                    <h3 className="text-xs font-bold text-slate-900 truncate">
                      {currentConfig.imageTitle}
                    </h3>
                    <p className="text-[10px] text-slate-500 truncate">
                      {currentConfig.imageSubtitle}
                    </p>
                  </div>
                </div>
              </div>

            </div>
          </div>

        </div>
      </main>

      {/* 3. Clean White Footer */}
      <footer className="bg-white border-t border-slate-200/80 py-4 text-xs text-slate-500">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-3 text-center sm:text-left">
          <p>© 2026 Dinas Pertanian dan Ketahanan Pangan Kabupaten Mojokerto.</p>
          <div className="flex items-center gap-6 text-[11px]">
            <a href="#" className="hover:text-slate-800 transition">Kebijakan Privasi</a>
            <a href="#" className="hover:text-slate-800 transition">Syarat & Ketentuan</a>
            <a href="#" className="hover:text-slate-800 transition">Bantuan Layanan</a>
          </div>
        </div>
      </footer>

    </div>
  );
}



