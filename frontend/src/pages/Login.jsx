import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Sprout, Lock, User, ShieldCheck, Tractor, 
  Briefcase, ArrowRight, CheckCircle2, Sparkles 
} from 'lucide-react';
import { useAuthStore } from '../store/authStore';

export default function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuthStore();
  const navigate = useNavigate();

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
      // Redirect based on role
      if (res.user.role === 'ADMIN' || res.user.role === 'PIMPINAN') {
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
      if (res.user.role === 'ADMIN' || res.user.role === 'PIMPINAN') {
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
    <div className="min-h-screen bg-slate-900 flex flex-col md:flex-row">
      {/* Left Branding Panel */}
      <div className="md:w-1/2 bg-gradient-to-br from-emerald-900 via-slate-900 to-emerald-950 p-8 md:p-14 flex flex-col justify-between relative overflow-hidden border-b md:border-b-0 md:border-r border-emerald-800/30">
        {/* Glow decorations */}
        <div className="absolute -top-24 -left-24 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-24 -right-24 w-96 h-96 bg-emerald-600/15 rounded-full blur-3xl pointer-events-none" />

        {/* Top Header */}
        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-500 to-green-400 flex items-center justify-center text-white shadow-lg shadow-emerald-500/30">
              <Sprout className="w-7 h-7 stroke-[2.2]" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight text-white font-display">
                E-PUPUK
              </h1>
              <p className="text-xs text-emerald-400 font-medium">
                Pemerintah Kabupaten Mojokerto
              </p>
            </div>
          </div>

          <div className="mt-12">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-300 text-xs font-semibold mb-4">
              <Sparkles className="w-3.5 h-3.5" /> Sistem Terintegrasi Subsidi Pupuk 2026
            </div>
            <h2 className="text-3xl lg:text-4xl font-black text-white leading-tight font-display">
              Transparansi & Akurasi Penyaluran Pupuk Bersubsidi
            </h2>
            <p className="mt-4 text-sm text-slate-300 leading-relaxed">
              Platform verifikasi berlapis berbasis foto KTP, citra lahan aktual, titik koordinat GPS, dan survei lapangan PPL secara langsung ke sawah petani di seluruh wilayah Mojokerto.
            </p>
          </div>
        </div>

        {/* Key Features bullet points */}
        <div className="relative z-10 my-8 space-y-3.5">
          <div className="flex items-center gap-3 text-slate-200 text-xs font-medium">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>Verifikasi Berkas KTP & Dokumen Kepemilikan Lahan</span>
          </div>
          <div className="flex items-center gap-3 text-slate-200 text-xs font-medium">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>Survei Fisik Petugas PPL dengan Titik Koordinat GPS</span>
          </div>
          <div className="flex items-center gap-3 text-slate-200 text-xs font-medium">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>Pengambilan Pupuk dengan Kode QR Digital Anti-Manipulasi</span>
          </div>
        </div>

        {/* Footer info */}
        <div className="relative z-10 text-xs text-slate-500 border-t border-slate-800/80 pt-4">
          Dinas Pertanian & Ketahanan Pangan Kabupaten Mojokerto &copy; 2026
        </div>
      </div>

      {/* Right Form Panel */}
      <div className="md:w-1/2 bg-slate-950 p-6 md:p-14 flex flex-col justify-center">
        <div className="max-w-md w-full mx-auto">
          <div className="mb-6">
            <h2 className="text-2xl font-black text-white font-display">
              Masuk ke Portal
            </h2>
            <p className="text-xs text-slate-400 mt-1">
              Gunakan akun terdaftar Anda untuk mengakses layanan
            </p>
          </div>

          {error && (
            <div className="mb-5 p-3 rounded-xl bg-rose-950/60 border border-rose-800/50 text-rose-300 text-xs flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-rose-500 animate-ping shrink-0" />
              {error}
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                Username
              </label>
              <div className="relative">
                <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="Masukkan username"
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-900 border border-slate-800 focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 rounded-xl text-white text-xs placeholder:text-slate-600 outline-hidden transition-all"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                Kata Sandi
              </label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-900 border border-slate-800 focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 rounded-xl text-white text-xs placeholder:text-slate-600 outline-hidden transition-all"
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 px-4 bg-gradient-to-r from-emerald-600 to-green-500 hover:from-emerald-500 hover:to-green-400 text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-900/30 flex items-center justify-center gap-2 transition-all duration-200 disabled:opacity-50 cursor-pointer"
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

          {/* Quick Demo Logins Section */}
          <div className="mt-8 pt-6 border-t border-slate-800">
            <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-3">
              ⚡ Akses Cepat Akun Demo (1-Klik Masuk)
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {/* Petani Budi */}
              <button
                type="button"
                onClick={() => handleQuickLogin('petani_budi', 'petani123')}
                className="p-3 text-left rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-800 hover:border-emerald-700/50 transition-all group cursor-pointer"
              >
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-lg bg-emerald-900/60 text-emerald-400 flex items-center justify-center shrink-0">
                    <Tractor className="w-3.5 h-3.5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-200 group-hover:text-emerald-300 truncate">
                      Petani Budi
                    </p>
                    <p className="text-[10px] text-slate-500 truncate">
                      Mojosari (Padi)
                    </p>
                  </div>
                </div>
              </button>

              {/* Petani Siti */}
              <button
                type="button"
                onClick={() => handleQuickLogin('petani_siti', 'petani123')}
                className="p-3 text-left rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-800 hover:border-emerald-700/50 transition-all group cursor-pointer"
              >
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-lg bg-emerald-900/60 text-emerald-400 flex items-center justify-center shrink-0">
                    <Tractor className="w-3.5 h-3.5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-200 group-hover:text-emerald-300 truncate">
                      Petani Siti
                    </p>
                    <p className="text-[10px] text-slate-500 truncate">
                      Trowulan (Jagung)
                    </p>
                  </div>
                </div>
              </button>

              {/* Admin */}
              <button
                type="button"
                onClick={() => handleQuickLogin('admin', 'admin123')}
                className="p-3 text-left rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-800 hover:border-rose-700/50 transition-all group cursor-pointer"
              >
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-lg bg-rose-950/60 text-rose-400 flex items-center justify-center shrink-0">
                    <ShieldCheck className="w-3.5 h-3.5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-200 group-hover:text-rose-300 truncate">
                      Admin Dinas
                    </p>
                    <p className="text-[10px] text-slate-500 truncate">
                      Verifikasi & Approval
                    </p>
                  </div>
                </div>
              </button>

              {/* PPL Ahmad */}
              <button
                type="button"
                onClick={() => handleQuickLogin('ppl_ahmad', 'ppl123')}
                className="p-3 text-left rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-800 hover:border-blue-700/50 transition-all group cursor-pointer"
              >
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-lg bg-blue-950/60 text-blue-400 flex items-center justify-center shrink-0">
                    <Briefcase className="w-3.5 h-3.5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-200 group-hover:text-blue-300 truncate">
                      PPL Ahmad
                    </p>
                    <p className="text-[10px] text-slate-500 truncate">
                      Survei Fisik Lapangan
                    </p>
                  </div>
                </div>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
