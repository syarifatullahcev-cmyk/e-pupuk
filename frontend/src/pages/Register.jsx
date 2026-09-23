import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { 
  Sprout, 
  User, 
  Lock, 
  Phone, 
  FileText, 
  ArrowLeft, 
  UserPlus, 
  ShieldCheck 
} from 'lucide-react';
import { toast } from 'react-hot-toast';

export default function Register() {
  const [formData, setFormData] = useState({
    namaLengkap: '',
    nik: '',
    nomorHp: '',
    username: '',
    password: '',
    confirmPassword: ''
  });
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    
    if (formData.password !== formData.confirmPassword) {
      toast.error('Kata Sandi dan Konfirmasi Kata Sandi tidak cocok');
      return;
    }

    if (formData.nik.length < 16) {
      toast.error('NIK wajib berisi 16 digit angka');
      return;
    }

    setLoading(true);
    // Simulate API registration
    setTimeout(() => {
      setLoading(false);
      toast.success('Pendaftaran akun petani berhasil! Silakan masuk.');
      navigate('/login/petani');
    }, 1200);
  };

  return (
    <div className="min-h-screen bg-[#f8fafc] font-sans text-slate-800 antialiased flex flex-col justify-between selection:bg-emerald-100 selection:text-emerald-800">
      
      {/* 1. Navigation Bar */}
      <header className="bg-white border-b border-slate-200/80 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-20">
            
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

      {/* 2. Main Register Container */}
      <main className="flex-1 flex items-center justify-center p-4 sm:p-6 lg:p-10">
        <div className="w-full max-w-5xl bg-white rounded-3xl border border-slate-200/80 shadow-xl overflow-hidden grid grid-cols-1 md:grid-cols-12 min-h-[640px]">
          
          {/* Left Column: Form */}
          <div className="md:col-span-6 lg:col-span-6 p-6 sm:p-10 flex flex-col justify-between">
            <div>
              
              {/* Title & Subtitle */}
              <div className="mb-6">
                <div className="inline-block px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider border mb-2 bg-[#ecfdf5] text-[#059669] border-[#a7f3d0]/70">
                  PENDAFTARAN PETANI BARU
                </div>
                <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
                  Buat Akun
                </h2>
                <p className="text-xs sm:text-sm text-slate-500 mt-1">
                  Bergabung dengan kami untuk mendapatkan alokasi pupuk bersubsidi resmi.
                </p>
              </div>

              {/* Register Form */}
              <form onSubmit={handleRegister} className="space-y-3.5">
                
                {/* Nama Lengkap */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Nama Lengkap
                  </label>
                  <div className="relative">
                    <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <input
                      type="text"
                      name="namaLengkap"
                      required
                      value={formData.namaLengkap}
                      onChange={handleChange}
                      placeholder="Masukkan nama sesuai KTP"
                      className="w-full pl-10 pr-4 py-2.5 bg-[#f8fafc] border border-slate-200/80 focus:bg-white focus:border-[#059669] focus:ring-2 focus:ring-[#059669]/20 rounded-xl text-slate-900 text-xs placeholder:text-slate-400 outline-none transition-all"
                    />
                  </div>
                </div>

                {/* NIK */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Nomor Induk Kependudukan (NIK)
                  </label>
                  <div className="relative">
                    <FileText className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <input
                      type="text"
                      name="nik"
                      required
                      maxLength={16}
                      value={formData.nik}
                      onChange={handleChange}
                      placeholder="Masukkan 16 digit NIK Anda"
                      className="w-full pl-10 pr-4 py-2.5 bg-[#f8fafc] border border-slate-200/80 focus:bg-white focus:border-[#059669] focus:ring-2 focus:ring-[#059669]/20 rounded-xl text-slate-900 text-xs placeholder:text-slate-400 outline-none transition-all"
                    />
                  </div>
                </div>

                {/* Nomor HP */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Nomor HP / WhatsApp
                  </label>
                  <div className="relative">
                    <Phone className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <input
                      type="tel"
                      name="nomorHp"
                      required
                      value={formData.nomorHp}
                      onChange={handleChange}
                      placeholder="+62 812-3456-7890"
                      className="w-full pl-10 pr-4 py-2.5 bg-[#f8fafc] border border-slate-200/80 focus:bg-white focus:border-[#059669] focus:ring-2 focus:ring-[#059669]/20 rounded-xl text-slate-900 text-xs placeholder:text-slate-400 outline-none transition-all"
                    />
                  </div>
                </div>

                {/* Username */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Username
                  </label>
                  <div className="relative">
                    <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <input
                      type="text"
                      name="username"
                      required
                      value={formData.username}
                      onChange={handleChange}
                      placeholder="admin"
                      className="w-full pl-10 pr-4 py-2.5 bg-[#f8fafc] border border-slate-200/80 focus:bg-white focus:border-[#059669] focus:ring-2 focus:ring-[#059669]/20 rounded-xl text-slate-900 text-xs placeholder:text-slate-400 outline-none transition-all"
                    />
                  </div>
                </div>

                {/* Password & Confirm Password in 2-cols */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Kata Sandi
                    </label>
                    <div className="relative">
                      <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                      <input
                        type="password"
                        name="password"
                        required
                        value={formData.password}
                        onChange={handleChange}
                        placeholder="secretpassword"
                        className="w-full pl-10 pr-4 py-2.5 bg-[#f8fafc] border border-slate-200/80 focus:bg-white focus:border-[#059669] focus:ring-2 focus:ring-[#059669]/20 rounded-xl text-slate-900 text-xs placeholder:text-slate-400 outline-none transition-all"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Konfirmasi Sandi
                    </label>
                    <div className="relative">
                      <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                      <input
                        type="password"
                        name="confirmPassword"
                        required
                        value={formData.confirmPassword}
                        onChange={handleChange}
                        placeholder="secretpassword"
                        className="w-full pl-10 pr-4 py-2.5 bg-[#f8fafc] border border-slate-200/80 focus:bg-white focus:border-[#059669] focus:ring-2 focus:ring-[#059669]/20 rounded-xl text-slate-900 text-xs placeholder:text-slate-400 outline-none transition-all"
                      />
                    </div>
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 px-4 bg-[#059669] hover:bg-[#047857] text-white font-bold text-xs rounded-xl shadow-md shadow-emerald-600/20 flex items-center justify-center gap-2 transition-all duration-200 disabled:opacity-50 cursor-pointer mt-4"
                >
                  {loading ? (
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <>
                      <UserPlus className="w-4 h-4" />
                      <span>Buat Akun</span>
                    </>
                  )}
                </button>

              </form>

              {/* Already have account */}
              <p className="mt-4 text-center text-xs text-slate-500">
                Sudah mempunyai akun?{' '}
                <Link
                  to="/login/petani"
                  className="text-[#059669] font-bold hover:underline"
                >
                  Masuk disini
                </Link>
              </p>

            </div>

            <div className="pt-4 mt-4 border-t border-slate-100 flex items-center gap-2 text-[11px] text-slate-400">
              <ShieldCheck className="w-4 h-4 text-[#059669] shrink-0" />
              <span>Data Anda terlindungi oleh sistem keamanan Dinas Pertanian.</span>
            </div>

          </div>

          {/* Right Column: Image Banner with Inset Frame & Overlay */}
          <div className="hidden md:block md:col-span-6 lg:col-span-6 relative p-4 sm:p-6 bg-slate-50/40">
            <div className="relative w-full h-full min-h-[520px] rounded-2xl overflow-hidden shadow-inner flex flex-col justify-end p-6">
              
              <img 
                src="/logingambar.jpg" 
                alt="Pendaftaran Petani E-PUPUK" 
                className="absolute inset-0 w-full h-full object-cover"
              />
              
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-black/20" />

              {/* Overlay Info Card at bottom */}
              <div className="relative z-10 bg-white/95 backdrop-blur-md p-4 rounded-2xl shadow-xl border border-white/60">
                <div className="flex items-center gap-3 mb-1.5">
                  <div className="w-8 h-8 rounded-xl bg-[#059669] text-white flex items-center justify-center font-bold shadow-sm shadow-emerald-600/30 shrink-0">
                    <Sprout className="w-4 h-4" />
                  </div>
                  <div className="min-w-0">
                    <h3 className="text-xs font-bold text-slate-900 truncate">
                      Pendaftaran Petani Terintegrasi
                    </h3>
                    <p className="text-[10px] text-slate-500 truncate">
                      Dinas Pertanian dan Ketahanan Pangan Kab. Mojokerto
                    </p>
                  </div>
                </div>
                <p className="text-[10px] text-slate-600 leading-relaxed">
                  Segera daftarkan NIK dan data lahan sawah Anda untuk mendapatkan kuota pupuk subsidi pada musim tanam tahun 2026.
                </p>
              </div>

            </div>
          </div>

        </div>
      </main>

      {/* 3. Clean White Footer */}
      <footer className="bg-white border-t border-slate-200/80 py-5 text-xs text-slate-500">
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


