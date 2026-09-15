import React, { useState, useEffect } from 'react';
import { 
  Plus, Tractor, MapPin, Calendar, FileText, QrCode, 
  AlertTriangle, RefreshCw, Eye, CheckCircle2, ChevronRight,
  ShieldCheck, ArrowUpRight, Sparkles, X, Map
} from 'lucide-react';
import { 
  applicationsApi, farmersApi, landsApi, distributionsApi 
} from '../services/api';
import { useAuthStore } from '../store/authStore';
import KPICard from '../components/KPICard';
import StatusBadge from '../components/StatusBadge';
import ProgressStepper from '../components/ProgressStepper';
import PhotoViewerModal from '../components/PhotoViewerModal';
import FileUploadZone from '../components/FileUploadZone';
import MapPicker from '../components/MapPicker';
import { formatCoord } from '../utils/format';

export default function PetaniDashboard() {
  const { user } = useAuthStore();
  const [stats, setStats] = useState(null);
  const [farmer, setFarmer] = useState(null);
  const [lands, setLands] = useState([]);
  const [applications, setApplications] = useState([]);
  const [fertilizers, setFertilizers] = useState([]);
  const [loading, setLoading] = useState(true);

  // Modals state
  const [showApplyModal, setShowApplyModal] = useState(false);
  const [showReviseModal, setShowReviseModal] = useState(false);
  const [showQRModal, setShowQRModal] = useState(false);
  const [selectedApp, setSelectedApp] = useState(null);
  const [selectedQR, setSelectedQR] = useState(null);

  // Photo viewer modal state
  const [viewerPhoto, setViewerPhoto] = useState({
    isOpen: false,
    title: '',
    url: '',
    secondaryUrl: '',
    secondaryTitle: '',
  });

  // Application form state
  const [formData, setFormData] = useState({
    land_id: '',
    fertilizer_id: '',
    jumlah_diajukan: '',
    alamat_lahan: '',
    latitude: -7.531234,
    longitude: 112.551234,
  });

  // Revise form state
  const [reviseKtpUrl, setReviseKtpUrl] = useState(null);
  const [reviseLahanUrl, setReviseLahanUrl] = useState(null);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [fRes, landsRes, appsRes, fertsRes, statsRes] = await Promise.all([
        farmersApi.getMe(),
        landsApi.getAll(),
        applicationsApi.getAll(),
        farmersApi.getFertilizers(),
        applicationsApi.getPetaniStats(),
      ]);

      setFarmer(fRes.data);
      setLands(landsRes.data);
      setApplications(appsRes.data);
      setFertilizers(fertsRes.data);
      setStats(statsRes.data);

      if (landsRes.data.length > 0) {
        setFormData((prev) => ({
          ...prev,
          land_id: landsRes.data[0].id,
          alamat_lahan: landsRes.data[0].alamat_lahan,
          latitude: landsRes.data[0].latitude || -7.531234,
          longitude: landsRes.data[0].longitude || 112.551234,
        }));
      }
      if (fertsRes.data.length > 0) {
        setFormData((prev) => ({ ...prev, fertilizer_id: fertsRes.data[0].id }));
      }
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleLandSelectChange = (e) => {
    const selectedLandId = parseInt(e.target.value);
    const selectedLand = lands.find((l) => l.id === selectedLandId);
    if (selectedLand) {
      setFormData((prev) => ({
        ...prev,
        land_id: selectedLandId,
        alamat_lahan: selectedLand.alamat_lahan,
        latitude: selectedLand.latitude || -7.531234,
        longitude: selectedLand.longitude || 112.551234,
      }));
    }
  };

  const handleCreateApplication = async (e) => {
    e.preventDefault();
    if (!formData.land_id || !formData.fertilizer_id || !formData.jumlah_diajukan) {
      alert('Harap lengkapi semua kolom yang wajib diisi.');
      return;
    }

    try {
      await applicationsApi.create({
        land_id: parseInt(formData.land_id),
        fertilizer_id: parseInt(formData.fertilizer_id),
        jumlah_diajukan: parseFloat(formData.jumlah_diajukan),
        alamat_lahan: formData.alamat_lahan,
        latitude: formData.latitude,
        longitude: formData.longitude,
      });
      setShowApplyModal(false);
      fetchData();
      alert('Pengajuan subsidi pupuk berhasil dikirim! Berkas Anda sedang dalam antrean verifikasi.');
    } catch (err) {
      alert(err.response?.data?.detail || 'Gagal mengirim pengajuan.');
    }
  };

  const handleReviseSubmit = async (e) => {
    e.preventDefault();
    if (!selectedApp) return;

    try {
      await applicationsApi.reviseDocs(selectedApp.id, {
        foto_ktp_url: reviseKtpUrl,
        foto_lahan_url: reviseLahanUrl,
      });
      setShowReviseModal(false);
      fetchData();
      alert('Perbaikan berkas berhasil diunggah! Status telah diperbarui ke Menunggu Verifikasi Berkas.');
    } catch (err) {
      alert(err.response?.data?.detail || 'Gagal memperbarui berkas.');
    }
  };

  const handleShowQR = (app) => {
    setSelectedApp(app);
    // Determine QR code hash
    const qrHash = app.distribution?.qr_code_hash || `EPUPUK-${app.id}-CLAIM-TOKEN`;
    setSelectedQR(qrHash);
    setShowQRModal(true);
  };

  return (
    <div className="space-y-8 pb-16">
      {/* Top Banner Header */}
      <div className="rounded-3xl bg-gradient-to-r from-emerald-900 via-emerald-800 to-green-900 text-white p-6 sm:p-8 relative overflow-hidden shadow-xl border border-emerald-700/50">
        <div className="absolute right-0 top-0 bottom-0 w-1/3 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-green-400/20 via-transparent to-transparent pointer-events-none" />
        
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <div className="flex items-center gap-2 text-emerald-300 text-xs font-bold uppercase tracking-wider mb-2">
              <Sparkles className="w-4 h-4" /> Portal Petani Kabupaten Mojokerto
            </div>
            <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
              Selamat Datang, {farmer?.nama || user?.nama || 'Petani'}!
            </h1>
            <p className="mt-1 text-xs sm:text-sm text-emerald-100 max-w-2xl leading-relaxed">
              Pantau status verifikasi berkas, jadwal survei fisik lahan PPL, dan klaim alokasi pupuk bersubsidi Anda secara transparan.
            </p>
          </div>

          <button
            onClick={() => setShowApplyModal(true)}
            className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-white hover:bg-emerald-50 text-emerald-950 font-bold text-xs shadow-lg shadow-emerald-950/20 hover:scale-[1.02] transition-all cursor-pointer shrink-0"
          >
            <Plus className="w-4 h-4 text-emerald-600 stroke-[3]" />
            <span>Ajukan Subsidi Baru</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        <KPICard
          title="Sisa Kuota Urea"
          value={`${stats?.kuota_tersedia_urea || 500} kg`}
          subtitle="Alokasi Musim Tanam 2026"
          icon={Tractor}
          color="emerald"
          badge="Subsidi"
        />
        <KPICard
          title="Sisa Kuota NPK"
          value={`${stats?.kuota_tersedia_npk || 400} kg`}
          subtitle="Alokasi Phonska Terdaftar"
          icon={Tractor}
          color="blue"
          badge="Subsidi"
        />
        <KPICard
          title="Pengajuan Berjalan"
          value={stats?.aktif || 0}
          subtitle="Tahap Verifikasi & Survei"
          icon={RefreshCw}
          color="amber"
          badge="Aktif"
        />
        <KPICard
          title="Siap Diambil / Selesai"
          value={(stats?.disetujui || 0) + (stats?.tersalurkan || 0)}
          subtitle="QR Code Aktif / Diterima"
          icon={CheckCircle2}
          color="purple"
          badge="Tersedia"
        />
      </div>

      {/* Main Profile & Farm Lahan Overview */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Farmer Profile Card with KTP Photo */}
        <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-emerald-600" />
                Data Identitas Petani
              </h2>
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                Terverifikasi
              </span>
            </div>

            {/* KTP Photo Preview Box */}
            <div className="mt-4">
              <label className="block text-[11px] font-semibold text-slate-500 uppercase tracking-wider mb-1.5">
                Foto KTP Terdaftar
              </label>
              <div 
                onClick={() => setViewerPhoto({
                  isOpen: true,
                  title: `Foto KTP: ${farmer?.nama}`,
                  url: farmer?.foto_ktp_url,
                  description: `NIK: ${farmer?.nik} | Alamat KTP: ${farmer?.alamat}`
                })}
                className="relative rounded-xl overflow-hidden border border-slate-200 bg-slate-50 group cursor-pointer aspect-16/10 flex items-center justify-center"
              >
                {farmer?.foto_ktp_url ? (
                  <>
                    <img 
                      src={farmer.foto_ktp_url} 
                      alt="Foto KTP" 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                    <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-1.5 text-white text-xs font-semibold">
                      <Eye className="w-4 h-4" /> Perbesar KTP
                    </div>
                  </>
                ) : (
                  <div className="text-xs text-slate-400">Belum ada foto KTP</div>
                )}
              </div>
            </div>

            {/* Profile Attributes */}
            <div className="mt-4 space-y-2.5 text-xs">
              <div>
                <span className="text-slate-400 block text-[11px]">Nama Lengkap</span>
                <span className="font-bold text-slate-800">{farmer?.nama || '-'}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">NIK</span>
                <span className="font-mono font-bold text-slate-800">{farmer?.nik || '-'}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Kelompok Tani</span>
                <span className="font-medium text-slate-700">{farmer?.farmer_group?.nama_kelompok || 'Poktan Sumber Makmur'}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Alamat Domisili</span>
                <span className="font-medium text-slate-700 leading-relaxed">{farmer?.alamat || '-'}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Registered Farm Lands with Farm Photos */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <Tractor className="w-4 h-4 text-emerald-600" />
              Lahan Pertanian Terdaftar ({lands.length})
            </h2>
            <span className="text-xs text-slate-500 font-medium">
              Mojokerto, Jawa Timur
            </span>
          </div>

          <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
            {lands.map((land) => (
              <div 
                key={land.id}
                className="rounded-xl border border-slate-200 overflow-hidden bg-slate-50/50 hover:bg-slate-50 transition-all flex flex-col justify-between"
              >
                {/* Lahan Photo Box */}
                <div 
                  onClick={() => setViewerPhoto({
                    isOpen: true,
                    title: `Foto Lahan: ${land.lokasi_deskripsi || 'Lahan Pertanian'}`,
                    url: land.foto_lahan_url,
                    description: `Luas: ${(Number(land.luas_m2 || 0) / 10000).toFixed(2)} Ha (${land.luas_m2} m²) | Alamat: ${land.alamat_lahan} | Koordinat: ${formatCoord(land.latitude)}, ${formatCoord(land.longitude)}`
                  })}
                  className="relative aspect-16/9 bg-slate-200 overflow-hidden group cursor-pointer"
                >
                  {land.foto_lahan_url ? (
                    <>
                      <img 
                        src={land.foto_lahan_url} 
                        alt={land.lokasi_deskripsi} 
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                      <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-1.5 text-white text-xs font-semibold">
                        <Eye className="w-4 h-4" /> Lihat Foto Lahan
                      </div>
                    </>
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-xs text-slate-400">
                      Foto Lahan Belum Ada
                    </div>
                  )}
                  <div className="absolute top-2 left-2 px-2 py-0.5 rounded-md bg-black/60 text-white text-[10px] font-bold backdrop-blur-xs">
                    {land.commodity?.nama_komoditas || 'Padi'}
                  </div>
                </div>

                <div className="p-4 flex-1 flex flex-col justify-between text-xs space-y-2">
                  <div>
                    <h4 className="font-bold text-slate-900 text-sm">
                      {land.lokasi_deskripsi || 'Lahan Pertanian'}
                    </h4>
                    <p className="text-slate-500 text-[11px] mt-0.5 flex items-start gap-1">
                      <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0 mt-0.5" />
                      <span>{land.alamat_lahan}</span>
                    </p>
                  </div>

                  <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between text-[11px]">
                    <span className="text-slate-500">
                      Luas: <strong className="text-slate-800 font-semibold">{land.luas_m2} m²</strong>
                    </span>
                    <span className="font-mono text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-200">
                      {formatCoord(land.latitude)}, {formatCoord(land.longitude)}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Active Subsidies Applications Section with 6-Stage Stepper */}
      <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-6">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div>
            <h2 className="text-base font-bold text-slate-900">
              Daftar Pengajuan Subsidi Pupuk & Progres Pelacakan
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Pantau perjalanan berkas verifikasi dari pengajuan hingga pengambilan pupuk
            </p>
          </div>
          <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-slate-100 text-slate-700">
            {applications.length} Pengajuan
          </span>
        </div>

        {applications.length === 0 ? (
          <div className="py-12 text-center">
            <Tractor className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-sm font-bold text-slate-700">Belum Ada Pengajuan Subsidi</p>
            <p className="text-xs text-slate-400 mt-1">
              Klik tombol "Ajukan Subsidi Baru" di atas untuk mengajukan alokasi pupuk bersubsidi.
            </p>
          </div>
        ) : (
          <div className="space-y-6">
            {applications.map((app) => {
              const isNeedsRevision = app.status === 'PERLU_PERBAIKAN_BERKAS';
              const isReadyClaim = app.status === 'DIJADWALKAN_DISTRIBUSI';
              const isClaimed = app.status === 'TERSALURKAN';

              return (
                <div
                  key={app.id}
                  className="rounded-2xl border border-slate-200 bg-white p-5 sm:p-6 shadow-xs hover:border-slate-300 transition-all space-y-4"
                >
                  {/* Top Bar of Application Card */}
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-mono font-bold text-slate-400">
                          #{app.id}
                        </span>
                        <h3 className="text-sm sm:text-base font-black text-slate-900">
                          Pupuk {app.fertilizer?.nama_pupuk} — {app.jumlah_diajukan} {app.fertilizer?.satuan || 'kg'}
                        </h3>
                      </div>
                      <p className="text-xs text-slate-500 mt-0.5 flex items-center gap-1.5">
                        <Calendar className="w-3.5 h-3.5 text-slate-400" />
                        <span>
                          Diajukan pada{' '}
                          {new Date(app.tanggal_pengajuan).toLocaleDateString('id-ID', {
                            day: 'numeric',
                            month: 'long',
                            year: 'numeric',
                          })}
                        </span>
                        <span>•</span>
                        <span>Lahan: {app.land?.lokasi_deskripsi || 'Lahan Sawah'}</span>
                      </p>
                    </div>

                    <div className="flex items-center gap-2">
                      <StatusBadge status={app.status} />

                      {/* Action buttons */}
                      {isNeedsRevision && (
                        <button
                          onClick={() => {
                            setSelectedApp(app);
                            setShowReviseModal(true);
                          }}
                          className="px-3 py-1.5 rounded-lg bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-sm animate-bounce cursor-pointer"
                        >
                          <AlertTriangle className="w-3.5 h-3.5" /> Perbaiki Berkas
                        </button>
                      )}

                      {(isReadyClaim || isClaimed) && (
                        <button
                          onClick={() => handleShowQR(app)}
                          className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-sm shadow-emerald-200 cursor-pointer"
                        >
                          <QrCode className="w-3.5 h-3.5" /> {isClaimed ? 'Bukti Ambil' : 'Lihat QR Tiket'}
                        </button>
                      )}
                    </div>
                  </div>

                  {/* 6-Stage Progress Stepper Component */}
                  <div className="bg-slate-50/60 rounded-xl p-3 sm:p-4 border border-slate-100">
                    <ProgressStepper status={app.status} />
                  </div>

                  {/* Summary row: Verified Photos & Coordinates Snapshot */}
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs bg-slate-50 rounded-xl p-3.5 border border-slate-200/80">
                    <div className="flex items-center gap-3">
                      <div 
                        onClick={() => setViewerPhoto({
                          isOpen: true,
                          title: `KTP Petani (Snapshot #${app.id})`,
                          url: app.foto_ktp_snapshot_url,
                          description: 'Dokumen KTP yang digunakan saat pengajuan ini dibuat'
                        })}
                        className="w-12 h-10 rounded-lg overflow-hidden border border-slate-300 bg-white shrink-0 cursor-pointer group relative"
                      >
                        <img 
                          src={app.foto_ktp_snapshot_url} 
                          alt="Snapshot KTP" 
                          className="w-full h-full object-cover group-hover:scale-110 transition-transform"
                        />
                        <div className="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white">
                          <Eye className="w-3 h-3" />
                        </div>
                      </div>
                      <div>
                        <span className="text-slate-400 block text-[10px] uppercase font-bold">KTP Snapshot</span>
                        <span className="font-semibold text-slate-700">Terlampir</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <div 
                        onClick={() => setViewerPhoto({
                          isOpen: true,
                          title: `Foto Lahan (Snapshot #${app.id})`,
                          url: app.foto_lahan_snapshot_url,
                          description: `Alamat Lahan: ${app.alamat_lahan}`
                        })}
                        className="w-12 h-10 rounded-lg overflow-hidden border border-slate-300 bg-white shrink-0 cursor-pointer group relative"
                      >
                        <img 
                          src={app.foto_lahan_snapshot_url} 
                          alt="Snapshot Lahan" 
                          className="w-full h-full object-cover group-hover:scale-110 transition-transform"
                        />
                        <div className="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white">
                          <Eye className="w-3 h-3" />
                        </div>
                      </div>
                      <div>
                        <span className="text-slate-400 block text-[10px] uppercase font-bold">Lahan Snapshot</span>
                        <span className="font-semibold text-slate-700">Terlampir</span>
                      </div>
                    </div>

                    <div>
                      <span className="text-slate-400 block text-[10px] uppercase font-bold">Koordinat Lahan</span>
                      <span className="font-mono text-emerald-800 font-semibold truncate block">
                        {formatCoord(app.latitude)}, {formatCoord(app.longitude)}
                      </span>
                    </div>
                  </div>

                  {/* Inspection or Approval Notes from Admin / PPL */}
                  {app.catatan_admin_berkas && (
                    <div className="text-xs p-3 rounded-xl bg-amber-50/70 border border-amber-200/80 text-amber-900 flex items-start gap-2">
                      <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                      <div>
                        <strong className="font-bold">Catatan Admin: </strong>
                        <span>{app.catatan_admin_berkas}</span>
                      </div>
                    </div>
                  )}

                  {app.survey && (
                    <div className="text-xs p-3 rounded-xl bg-blue-50/70 border border-blue-200/80 text-blue-900 flex items-start justify-between gap-3">
                      <div>
                        <strong className="font-bold">Hasil Survei PPL Lapangan: </strong>
                        <p className="mt-0.5">
                          Kondisi Lahan: <span className="font-semibold">{app.survey.kondisi_fisik_lahan}</span> | 
                          Tanaman: <span className="font-semibold">{app.survey.kondisi_tanaman}</span> | 
                          Rekomendasi: <span className="font-bold text-emerald-700">{app.survey.rekomendasi}</span>
                        </p>
                        {app.survey.catatan_ppl && (
                          <p className="mt-1 text-slate-600 italic">"{app.survey.catatan_ppl}"</p>
                        )}
                      </div>
                      {app.survey.foto_survei_urls?.[0] && (
                        <button
                          type="button"
                          onClick={() => setViewerPhoto({
                            isOpen: true,
                            title: `Foto Survei Lapangan PPL (Pengajuan #${app.id})`,
                            url: app.survey.foto_survei_urls[0],
                            description: `Hasil Pemeriksaan Lapangan oleh Petugas PPL`
                          })}
                          className="px-2 py-1 rounded bg-blue-100 hover:bg-blue-200 text-blue-800 text-[11px] font-semibold shrink-0 cursor-pointer"
                        >
                          Lihat Foto Survei
                        </button>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Modal: Ajukan Subsidi Baru */}
      {showApplyModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-2xl w-full overflow-hidden max-h-[92vh] flex flex-col">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <div>
                <h3 className="text-base font-bold text-slate-900">
                  Form Pengajuan Subsidi Pupuk
                </h3>
                <p className="text-xs text-slate-500">
                  Pilih lahan terdaftar dan tentukan jumlah pupuk yang diajukan
                </p>
              </div>
              <button
                onClick={() => setShowApplyModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateApplication} className="p-6 overflow-y-auto space-y-4">
              {/* Select Land */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Pilih Lahan Pertanian <span className="text-rose-500">*</span>
                </label>
                <select
                  value={formData.land_id}
                  onChange={handleLandSelectChange}
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  required
                >
                  {lands.map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.lokasi_deskripsi} ({l.luas_m2} m² - {l.commodity?.nama_komoditas || 'Komoditas'})
                    </option>
                  ))}
                </select>
              </div>

              {/* Select Fertilizer & Kg */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Jenis Pupuk Bersubsidi <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={formData.fertilizer_id}
                    onChange={(e) => setFormData({ ...formData, fertilizer_id: e.target.value })}
                    className="w-full px-3 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                    required
                  >
                    {fertilizers.map((f) => (
                      <option key={f.id} value={f.id}>
                        {f.nama_pupuk} ({f.satuan})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Jumlah yang Diajukan (kg) <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="500"
                    value={formData.jumlah_diajukan}
                    onChange={(e) => setFormData({ ...formData, jumlah_diajukan: e.target.value })}
                    placeholder="Contoh: 200"
                    className="w-full px-3 py-2.5 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden font-semibold"
                    required
                  />
                  <span className="text-[10px] text-slate-400 mt-0.5 block">
                    Batas kuota maksimal per pengajuan: 500 kg
                  </span>
                </div>
              </div>

              {/* Address details */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Alamat Lengkap Lokasi Lahan
                </label>
                <input
                  type="text"
                  value={formData.alamat_lahan}
                  onChange={(e) => setFormData({ ...formData, alamat_lahan: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden"
                  required
                />
              </div>

              {/* Map Coordinate Picker */}
              <div>
                <MapPicker
                  initialLat={formData.latitude}
                  initialLng={formData.longitude}
                  onChange={(pos) => setFormData({ ...formData, ...pos })}
                />
              </div>

              {/* Notice that photos are snapshot automatically from profile and land */}
              <div className="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-900 text-xs flex items-center gap-2.5">
                <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
                <span>
                  Sistem otomatis melampirkan foto KTP resmi Anda dan foto lahan terbaru ke dalam berkas pengajuan ini.
                </span>
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowApplyModal(false)}
                  className="px-4 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-md shadow-emerald-200 transition-colors cursor-pointer"
                >
                  Kirim Pengajuan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Perbaiki Berkas (PERLU_PERBAIKAN_BERKAS) */}
      {showReviseModal && selectedApp && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-lg w-full overflow-hidden">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-orange-50">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-orange-600" />
                <h3 className="text-base font-bold text-orange-950">
                  Perbaikan Berkas Pengajuan #{selectedApp.id}
                </h3>
              </div>
              <button
                onClick={() => setShowReviseModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleReviseSubmit} className="p-6 space-y-4">
              <div className="p-3 rounded-xl bg-amber-50 border border-amber-200 text-amber-900 text-xs">
                <strong>Catatan Admin: </strong> {selectedApp.catatan_admin_berkas || 'Periksa kembali kejelasan foto KTP atau foto lahan.'}
              </div>

              <FileUploadZone
                label="Unggah Ulang Foto KTP Petani (Jika Diminta)"
                category="ktp"
                initialUrl={selectedApp.foto_ktp_snapshot_url}
                onUploadSuccess={(url) => setReviseKtpUrl(url)}
              />

              <FileUploadZone
                label="Unggah Ulang Foto Lahan Pertanian (Jika Diminta)"
                category="lahan"
                initialUrl={selectedApp.foto_lahan_snapshot_url}
                onUploadSuccess={(url) => setReviseLahanUrl(url)}
              />

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowReviseModal(false)}
                  className="px-4 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors"
                >
                  Tutup
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-xs font-bold shadow-md shadow-orange-200 transition-colors cursor-pointer"
                >
                  Kirim Berkas Perbaikan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: QR Code Pengambilan Pupuk */}
      {showQRModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-sm w-full overflow-hidden p-6 text-center space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200">
                Tiket Pengambilan Pupuk
              </span>
              <button
                onClick={() => setShowQRModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* QR Mock Display */}
            <div className="p-4 bg-slate-900 rounded-2xl border-4 border-emerald-500/30 flex flex-col items-center justify-center">
              <QrCode className="w-44 h-44 text-white" />
              <p className="mt-3 font-mono font-bold text-xs text-emerald-400 tracking-wider">
                {selectedQR}
              </p>
            </div>

            <div>
              <h4 className="text-sm font-bold text-slate-900">
                Tunjukkan QR Code ke Petugas Kiosk / PPL
              </h4>
              <p className="text-xs text-slate-500 mt-1 leading-relaxed">
                Petugas kios pupuk resmi akan memindai kode ini untuk validasi dan penyerahan fisik pupuk bersubsidi Anda.
              </p>
            </div>

            <button
              onClick={() => setShowQRModal(false)}
              className="w-full py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs transition-colors"
            >
              Selesai
            </button>
          </div>
        </div>
      )}

      {/* Photo Viewer Modal */}
      <PhotoViewerModal
        isOpen={viewerPhoto.isOpen}
        onClose={() => setViewerPhoto({ ...viewerPhoto, isOpen: false })}
        title={viewerPhoto.title}
        imageUrl={viewerPhoto.url}
        secondaryImageUrl={viewerPhoto.secondaryUrl}
        secondaryTitle={viewerPhoto.secondaryTitle}
        description={viewerPhoto.description}
      />
    </div>
  );
}
