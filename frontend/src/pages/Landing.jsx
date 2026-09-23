import React from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Sprout, 
  ArrowRight, 
  ShieldCheck, 
  User, 
  FileText, 
  Briefcase, 
  Check, 
  MapPin, 
  QrCode, 
  Headphones,
  PhoneCall,
  ChevronRight
} from 'lucide-react';

export default function Landing() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-white font-sans text-slate-800 antialiased selection:bg-emerald-100 selection:text-emerald-800">
      
      {/* Navigation Bar */}
      <nav className="bg-white border-b border-slate-100 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-20">
            
            {/* Logo */}
            <div 
              className="flex items-center gap-3 cursor-pointer"
              onClick={() => navigate('/')}
            >
              <div className="w-10 h-10 rounded-xl bg-emerald-600 flex items-center justify-center text-white shadow-md shadow-emerald-600/20">
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
            </div>

            {/* Menu Links */}
            <div className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-600">
              <a href="#portal" className="hover:text-emerald-600 transition-colors">Pilihan Portal</a>
              <a href="#keunggulan" className="hover:text-emerald-600 transition-colors">Keunggulan</a>
              <a href="#alur" className="hover:text-emerald-600 transition-colors">Alur Pengajuan</a>
              <a href="#kontak" className="hover:text-emerald-600 transition-colors">Bantuan</a>
            </div>
            
            {/* Action Buttons */}
            <div className="flex items-center gap-4">
              <button 
                onClick={() => navigate('/login')}
                className="text-slate-700 hover:text-emerald-600 text-sm font-semibold transition-colors cursor-pointer"
              >
                Masuk
              </button>
              <button 
                onClick={() => navigate('/register')}
                className="bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-full text-sm font-bold shadow-sm transition-all cursor-pointer"
              >
                Daftar Petani
              </button>
            </div>

          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-12 lg:py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-12 gap-10 lg:gap-12 items-center">
            
            {/* Left Content */}
            <div className="lg:col-span-6 space-y-6">
              
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/40 text-emerald-700 text-xs font-semibold bg-emerald-50/50">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                <span>Portal Resmi Alokasi Pupuk Bersubsidi</span>
              </div>
              
              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-slate-900 tracking-tight leading-[1.18]">
                Penyaluran Pupuk Bersubsidi di Mojokerto dengan <span className="text-emerald-500">Mudah</span> , <span className="text-emerald-500">Transparan</span> dan <span className="text-emerald-500">Tepat Sasaran</span>
              </h1>
              
              <p className="text-slate-600 text-sm sm:text-base leading-relaxed">
                Platform pelayanan digital bagi kelompok tani dan petani di seluruh Kabupaten Mojokerto untuk pengajuan alokasi kuota pupuk, verifikasi lapangan PPL, serta pengambilan pupuk menggunakan kode QR resmi.
              </p>

              <div className="flex flex-col sm:flex-row gap-3 pt-2">
                <button 
                  onClick={() => navigate('/register')}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white px-6 py-3 rounded-xl font-bold text-sm shadow-md shadow-emerald-600/20 transition-all flex items-center justify-center gap-2 cursor-pointer"
                >
                  <span>Minta Subsidi Pupuk</span>
                  <ArrowRight className="w-4 h-4" />
                </button>

                <button 
                  onClick={() => {
                    const el = document.getElementById('portal');
                    el?.scrollIntoView({ behavior: 'smooth' });
                  }}
                  className="bg-slate-100 hover:bg-slate-200 text-slate-700 px-6 py-3 rounded-xl font-semibold text-sm transition-all flex items-center justify-center gap-2 cursor-pointer"
                >
                  <span>Pilih Portal Akses</span>
                </button>
              </div>

            </div>

            {/* Right Content: Smart Farming Image */}
            <div className="lg:col-span-6">
              <div className="rounded-3xl overflow-hidden shadow-xl border border-slate-100">
                <img 
                  src="/hero-gambar-lading-page.jpg" 
                  alt="Petani Modern Smart Farming di Mojokerto" 
                  className="w-full h-80 sm:h-96 lg:h-[400px] object-cover"
                />
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* Section: Pilih Portal Sesuai Peran Anda */}
      <section id="portal" className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center max-w-3xl mx-auto mb-12">
            <div className="inline-flex items-center px-3 py-1 rounded-full border border-emerald-500/40 text-emerald-700 text-[11px] font-bold uppercase tracking-wider mb-3">
              AKSES LAYANAN TERPADU
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900">
              Pilih Portal Sesuai Peran Anda
            </h2>
            <p className="text-xs sm:text-sm text-slate-500 mt-2">
              Sistem terintegrasi untuk petani, tim penyuluh lapangan (PPL), serta admin verifikator dinas.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl mx-auto">
            
            {/* 1. Portal Petani*/}
            <div className="bg-white rounded-2xl border border-slate-200 p-6 flex flex-col justify-between shadow-xs hover:shadow-md transition-all relative">
              
              {/* Badge Paling Populer */}
              <div className="absolute -top-3 right-6 bg-emerald-600 text-white text-[10px] font-bold px-3 py-1 rounded-full uppercase tracking-wider">
                PALING POPULER
              </div>

              <div>
                <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-5">
                  <User className="w-6 h-6" />
                </div>

                <h3 className="text-lg font-bold text-slate-900 mb-2">
                  Portal Petani
                </h3>
                <p className="text-xs text-slate-500 leading-relaxed mb-6">
                  Pengajuan kuota alokasi pupuk bersubsidi, cek status verifikasi lahan, dan unduh QR Code penebusan pupuk di kios rekanan.
                </p>

                <div className="space-y-2.5 mb-8">
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Pengajuan alokasi musim tanam (MT I, II, III)</span>
                  </div>
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Generate E-Kupon & QR Code Tebus</span>
                  </div>
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Tracking status survei PPL berkala</span>
                  </div>
                </div>
              </div>

              <div className="space-y-3 pt-4">
                <button
                  onClick={() => navigate('/login/petani')}
                  className="w-full py-3 px-4 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition-all flex items-center justify-center gap-2 cursor-pointer shadow-sm"
                >
                  <span>Masuk Portal Petani</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
                <p className="text-center text-[11px] text-emerald-700 hover:underline cursor-pointer" onClick={() => navigate('/register')}>
                  Belum punya akun? Daftar Sekarang
                </p>
              </div>
            </div>

            {/* 2. Portal Admin Dinas */}
            <div className="bg-white rounded-2xl border border-slate-200 p-6 flex flex-col justify-between shadow-xs hover:shadow-md transition-all">
              <div>
                <div className="w-12 h-12 rounded-xl bg-slate-100 text-slate-700 flex items-center justify-center mb-5">
                  <FileText className="w-6 h-6" />
                </div>

                <h3 className="text-lg font-bold text-slate-900 mb-2">
                  Portal Admin Dinas
                </h3>
                <p className="text-xs text-slate-500 leading-relaxed mb-6">
                  Verifikasi dokumen KTP & bukti lahan, penugasan survei ke PPL, persetujuan kuota pupuk, dan pemantauan stok kios se-Kabupaten.
                </p>

                <div className="space-y-2.5 mb-8">
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Validasi NIK Dukcapil & SPPT Lahan</span>
                  </div>
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Disposisi penugasan PPL per desa</span>
                  </div>
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Dashboard analitik dan audit serapan kuota</span>
                  </div>
                </div>
              </div>

              <div className="pt-4">
                <button
                  onClick={() => navigate('/login/admin')}
                  className="w-full py-3 px-4 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl transition-all flex items-center justify-center gap-2 cursor-pointer shadow-sm"
                >
                  <span>Masuk Portal Admin</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* 3. Portal Petugas PPL */}
            <div className="bg-white rounded-2xl border border-slate-200 p-6 flex flex-col justify-between shadow-xs hover:shadow-md transition-all">
              <div>
                <div className="w-12 h-12 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center mb-5">
                  <Briefcase className="w-6 h-6" />
                </div>

                <h3 className="text-lg font-bold text-slate-900 mb-2">
                  Portal Petugas PPL
                </h3>
                <p className="text-xs text-slate-500 leading-relaxed mb-6">
                  Penerimaan tugas survei sawah fisik, verifikasi komoditas vegetasi, geotagging koordinat batas lahan, dan unggah berita acara.
                </p>

                <div className="space-y-2.5 mb-8">
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Input GPS Poligon & foto lapangan langsung</span>
                  </div>
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Verifikasi kecocokan jenis tanaman pangan</span>
                  </div>
                  <div className="flex items-start gap-2 text-xs text-slate-600">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Tanda tangan Berita Acara Lapangan Digital</span>
                  </div>
                </div>
              </div>

              <div className="pt-4">
                <button
                  onClick={() => navigate('/login/ppl')}
                  className="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl transition-all flex items-center justify-center gap-2 cursor-pointer shadow-sm"
                >
                  <span>Masuk Portal PPL</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* Section: Mengapa Menggunakan E-PUPUK? */}
      <section id="keunggulan" className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center max-w-3xl mx-auto mb-14">
            <div className="inline-flex items-center px-3 py-1 rounded-full border border-emerald-500/40 text-emerald-700 text-[11px] font-bold uppercase tracking-wider mb-3">
              KEUNGGULAN SISTEM
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900">
              Mengapa Menggunakan E-PUPUK?
            </h2>
            <p className="text-xs sm:text-sm text-slate-500 mt-2">
              Mencegah penyalahgunaan subsidi pupuk melalui digitalisasi data terintegrasi dan transparan dari hulu ke hilir.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 max-w-6xl mx-auto">
            
            <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-2xs hover:shadow-md transition-all">
              <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-4">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 mb-2">Validasi NIK & SPPT</h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Terhubung langsung dengan server kependudukan Dukcapil dan data blok lahan untuk memastikan petani pemilik dan penggarap valid.
              </p>
            </div>

            <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-2xs hover:shadow-md transition-all">
              <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-4">
                <MapPin className="w-5 h-5" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 mb-2">Geotagging GPS Poligon</h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Petugas PPL memetakan batas koordinat fisik sawah langsung dari lapangan, meniadakan risiko klaim lahan fiktif atau ganda.
              </p>
            </div>

            <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-2xs hover:shadow-md transition-all">
              <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-4">
                <QrCode className="w-5 h-5" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 mb-2">QR Code Anti-Duplikasi</h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Pengambilan pupuk di kios pengecer resmi menggunakan token QR dinamis terenkripsi yang langsung hangus setelah ditransaksikan.
              </p>
            </div>

            <div className="bg-white border border-slate-200/80 rounded-2xl p-6 shadow-2xs hover:shadow-md transition-all">
              <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-4">
                <Headphones className="w-5 h-5" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 mb-2">Layanan Aduan Cepat</h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Saluran pengaduan langsung melalui WhatsApp Resmi Disperta dan posko pendampingan Poktan jika terjadi kendala pada penebusan.
              </p>
            </div>

          </div>
        </div>
      </section>

      {/* Section: 4 Langkah Mudah Pengajuan Alokasi */}
      <section id="alur" className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center max-w-3xl mx-auto mb-14">
            <div className="inline-flex items-center px-3 py-1 rounded-full border border-emerald-500/40 text-emerald-700 text-[11px] font-bold uppercase tracking-wider mb-3">
              ALUR PENGAJUAN
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900">
              4 Langkah Mudah Pengajuan Alokasi
            </h2>
            <p className="text-xs sm:text-sm text-slate-500 mt-2">
              Tata cara ringkas dan teratur mulai dari pendaftaran hingga membawa pulang pupuk subsidi.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 max-w-6xl mx-auto">
            
            {/* Step 01 */}
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-2xs flex flex-col justify-between">
              <div>
                <div className="w-9 h-9 rounded-full bg-emerald-600 text-white font-bold text-xs flex items-center justify-center mb-5">
                  01
                </div>
                <h4 className="text-sm font-bold text-slate-900 mb-2">Daftar Akun Petani</h4>
                <p className="text-xs text-slate-500 leading-relaxed mb-6">
                  Isi data diri dengan 16-digit NIK e-KTP, nama lengkap, nomor HP aktif, dan pilih Kelompok Tani (Poktan) di desa Anda.
                </p>
              </div>
              <div className="pt-2">
                <span className="text-[11px] font-semibold text-emerald-700">
                  Waktu proses: 5 Menit
                </span>
              </div>
            </div>

            {/* Step 02 */}
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-2xs flex flex-col justify-between">
              <div>
                <div className="w-9 h-9 rounded-full bg-emerald-600 text-white font-bold text-xs flex items-center justify-center mb-5">
                  02
                </div>
                <h4 className="text-sm font-bold text-slate-900 mb-2">Ajukan Data Lahan</h4>
                <p className="text-xs text-slate-500 leading-relaxed mb-6">
                  Pilih jenis komoditas tanam (Padi/Jagung/Kedelai), kebutuhan jenis pupuk (Urea/NPK Phonska), dan unggah bukti kepemilikan/sewa.
                </p>
              </div>
              <div className="pt-2">
                <span className="text-[11px] font-semibold text-emerald-700">
                  Integrasi e-RDKK
                </span>
              </div>
            </div>

            {/* Step 03 */}
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-2xs flex flex-col justify-between">
              <div>
                <div className="w-9 h-9 rounded-full bg-emerald-600 text-white font-bold text-xs flex items-center justify-center mb-5">
                  03
                </div>
                <h4 className="text-sm font-bold text-slate-900 mb-2">Survei Lapangan PPL</h4>
                <p className="text-xs text-slate-500 leading-relaxed mb-6">
                  Petugas PPL setempat melakukan peninjauan fisik sawah, geotagging koordinat poligon, serta menandatangani berita acara verifikasi.
                </p>
              </div>
              <div className="pt-2">
                <span className="text-[11px] font-semibold text-emerald-700">
                  Verifikasi 1x24 Jam
                </span>
              </div>
            </div>

            {/* Step 04 */}
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-2xs flex flex-col justify-between">
              <div>
                <div className="w-9 h-9 rounded-full bg-emerald-600 text-white font-bold text-xs flex items-center justify-center mb-5">
                  04
                </div>
                <h4 className="text-sm font-bold text-slate-900 mb-2">Penebusan di Kios</h4>
                <p className="text-xs text-slate-500 leading-relaxed mb-6">
                  Tunjukkan QR Code resmi atau sebutkan NIK di kios resmi rekanan di kecamatan Anda. Bayar sesuai HET resmi pemerintah.
                </p>
              </div>
              <div className="pt-2">
                <span className="text-[11px] font-semibold text-emerald-700">
                  Harga Eceran Tertinggi
                </span>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* Footer */}
      <footer id="kontak" className="bg-slate-950 text-slate-400 py-12 text-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8 pb-8 border-b border-slate-800">
            
            {/* Col 1 */}
            <div className="space-y-3">
              <div className="flex items-center gap-2.5 text-white">
                <div className="w-8 h-8 rounded-lg bg-emerald-600 flex items-center justify-center text-white font-bold">
                  <Sprout className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-white">E-PUPUK</h4>
                  <p className="text-[10px] text-slate-400">Kabupaten Mojokerto</p>
                </div>
              </div>
              <p className="text-slate-400 leading-relaxed text-[11px]">
                Inovasi tata kelola subsidi pupuk digital Dinas Pertanian dan Ketahanan Pangan Kabupaten Mojokerto demi mewujudkan kedaulatan pangan daerah yang mandiri dan berdaya saing.
              </p>
              <div className="flex items-center gap-2 pt-1 text-[10px] text-slate-400">
                <span className="bg-slate-900 px-2 py-0.5 rounded border border-slate-800">SPBE Terverifikasi</span>
                <span className="bg-slate-900 px-2 py-0.5 rounded border border-slate-800">Satu Data Pertanian</span>
              </div>
            </div>

            {/* Col 2 */}
            <div>
              <p className="text-white font-bold mb-3 uppercase tracking-wider text-[11px]">Kantor Pelayanan</p>
              <p className="leading-relaxed text-[11px] text-slate-400 space-y-1">
                <span>Dinas Pertanian dan Ketahanan Pangan</span><br />
                <span>Kabupaten Mojokerto</span><br />
                <span>Jl. RA Basuni No. 12, Sooko</span><br />
                <span>Kabupaten Mojokerto, Jawa Timur 61361</span><br />
                <span className="text-slate-500 mt-2 block">Jam Layanan: Senin - Jumat, 07.30 - 16.00 WIB</span>
              </p>
            </div>

            {/* Col 3 */}
            <div>
              <p className="text-white font-bold mb-3 uppercase tracking-wider text-[11px]">Akses Cepat</p>
              <ul className="space-y-1.5 text-[11px] text-slate-400">
                <li><button onClick={() => navigate('/login/petani')} className="hover:text-emerald-400 transition cursor-pointer">Portal Petani & Poktan</button></li>
                <li><button onClick={() => navigate('/login/ppl')} className="hover:text-emerald-400 transition cursor-pointer">Portal Petugas Lapangan (PPL)</button></li>
                <li><button onClick={() => navigate('/login/admin')} className="hover:text-emerald-400 transition cursor-pointer">Portal Admin Disperta</button></li>
                <li><button onClick={() => navigate('/login/petani')} className="hover:text-emerald-400 transition cursor-pointer">Cek Status NIK Alokasi</button></li>
                <li><a href="https://mojokertokab.go.id" target="_blank" rel="noreferrer" className="hover:text-emerald-400 transition">Portal Pemkab Mojokerto</a></li>
              </ul>
            </div>

            {/* Col 4 */}
            <div>
              <p className="text-white font-bold mb-3 uppercase tracking-wider text-[11px]">Kontak Resmi</p>
              <div className="space-y-2 text-[11px] text-slate-400">
                <p className="flex items-center gap-2">
                  <PhoneCall className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                  <span>(0321) 321890</span>
                </p>
                <p className="flex items-center gap-2">
                  <span className="text-emerald-400 shrink-0 font-bold">@</span>
                  <span>distan@mojokertokab.go.id</span>
                </p>
                <p className="flex items-center gap-2">
                  <span className="text-emerald-400 shrink-0 font-bold">WA</span>
                  <span>WhatsApp: 0812-3456-7890</span>
                </p>
              </div>
            </div>

          </div>

          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-slate-500 text-[11px]">
            <p>&copy; 2026 Pemerintah Kabupaten Mojokerto. Seluruh Hak Cipta Dilindungi.</p>
            <div className="flex gap-4">
              <a href="#" className="hover:text-slate-400">Kebijakan Privasi</a>
              <a href="#" className="hover:text-slate-400">Syarat & Ketentuan</a>
              <a href="#" className="hover:text-slate-400">Peta Situs</a>
            </div>
          </div>
        </div>
      </footer>

    </div>
  );
}
