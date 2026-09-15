import React, { useState, useEffect } from 'react';
import { 
  ShieldCheck, UserCheck, Award, FileText, Check, X, 
  AlertTriangle, Eye, MapPin, Calendar, Tractor, 
  Send, RefreshCw, Layers, ShieldAlert, Sparkles
} from 'lucide-react';
import { adminApi, applicationsApi } from '../services/api';
import KPICard from '../components/KPICard';
import StatusBadge from '../components/StatusBadge';
import ProgressStepper from '../components/ProgressStepper';
import PhotoViewerModal from '../components/PhotoViewerModal';

export default function AdminDashboard() {
  const [stats, setStats] = useState(null);
  const [applications, setApplications] = useState([]);
  const [pplOfficers, setPplOfficers] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [activeTab, setActiveTab] = useState('verifikasi'); // 'verifikasi', 'penugasan', 'approval', 'audit'
  const [loading, setLoading] = useState(true);

  // Selected item for actions
  const [selectedApp, setSelectedApp] = useState(null);
  const [actionNotes, setActionNotes] = useState('');
  const [selectedPplId, setSelectedPplId] = useState('');
  const [approvedKg, setApprovedKg] = useState('');

  // Modals
  const [showVerifyModal, setShowVerifyModal] = useState(false);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [showFinalModal, setShowFinalModal] = useState(false);

  // Photo viewer modal state
  const [viewerPhoto, setViewerPhoto] = useState({
    isOpen: false,
    title: '',
    url: '',
    secondaryUrl: '',
    secondaryTitle: '',
    description: '',
  });

  const fetchData = async () => {
    setLoading(true);
    try {
      const [sRes, aRes, pRes, lRes] = await Promise.all([
        adminApi.getStats(),
        applicationsApi.getAll(),
        adminApi.getPplOfficers(),
        adminApi.getAuditLogs(),
      ]);
      setStats(sRes.data);
      setApplications(aRes.data);
      setPplOfficers(pRes.data);
      setAuditLogs(lRes.data);

      if (pRes.data.length > 0) {
        setSelectedPplId(pRes.data[0].id);
      }
    } catch (e) {
      console.error('Error fetching admin data:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // Filter applications by tab
  const pendingVerifyApps = applications.filter((a) =>
    ['DIAJUKAN', 'MENUNGGU_VERIFIKASI_BERKAS'].includes(a.status)
  );
  const pendingAssignApps = applications.filter((a) =>
    ['BERKAS_TERVERIFIKASI'].includes(a.status)
  );
  const pendingFinalApps = applications.filter((a) =>
    ['MENUNGGU_PERSETUJUAN_AKHIR'].includes(a.status)
  );

  // Verification Actions
  const handleVerify = async (action) => {
    if (!selectedApp) return;
    try {
      await adminApi.verifyDocs(selectedApp.id, {
        action,
        catatan: actionNotes,
      });
      setShowVerifyModal(false);
      setActionNotes('');
      fetchData();
      alert(`Berkas pengajuan #${selectedApp.id} berhasil diproses: ${action}`);
    } catch (err) {
      alert(err.response?.data?.detail || 'Gagal memproses verifikasi berkas.');
    }
  };

  // PPL Assignment Action
  const handleAssignPPL = async () => {
    if (!selectedApp || !selectedPplId) return;
    try {
      await adminApi.assignPpl(selectedApp.id, {
        ppl_id: parseInt(selectedPplId),
        catatan: actionNotes,
      });
      setShowAssignModal(false);
      setActionNotes('');
      fetchData();
      alert(`Petugas PPL berhasil ditugaskan untuk pengajuan #${selectedApp.id}!`);
    } catch (err) {
      alert(err.response?.data?.detail || 'Gagal menugaskan PPL.');
    }
  };

  // Final Approval Action
  const handleFinalApprove = async (action) => {
    if (!selectedApp) return;
    try {
      await adminApi.finalApprove(selectedApp.id, {
        action,
        jumlah_disetujui: approvedKg ? parseFloat(approvedKg) : null,
        catatan: actionNotes,
      });
      setShowFinalModal(false);
      setActionNotes('');
      setApprovedKg('');
      fetchData();
      alert(`Keputusan akhir untuk pengajuan #${selectedApp.id} berhasil disimpan: ${action}`);
    } catch (err) {
      alert(err.response?.data?.detail || 'Gagal menyimpan keputusan akhir.');
    }
  };

  return (
    <div className="space-y-8 pb-16">
      {/* Top Banner */}
      <div className="rounded-3xl bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 text-white p-6 sm:p-8 relative overflow-hidden shadow-xl border border-slate-700">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <div className="flex items-center gap-2 text-rose-400 text-xs font-bold uppercase tracking-wider mb-2">
              <ShieldAlert className="w-4 h-4" /> Panel Administrasi & Pengambilan Keputusan
            </div>
            <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
              Dashboard Verifikasi Dinas Pertanian
            </h1>
            <p className="mt-1 text-xs sm:text-sm text-slate-300 max-w-2xl leading-relaxed">
              Verifikasi berkas foto KTP & citra lahan, tugaskan petugas PPL lapangan untuk survei fisik ke sawah, dan berikan persetujuan akhir penerbitan kuota pupuk subsidi.
            </p>
          </div>

          <button
            onClick={fetchData}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold border border-slate-700 transition-colors shrink-0 cursor-pointer"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            <span>Segarkan Data</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        <KPICard
          title="Verifikasi Berkas"
          value={stats?.menunggu_verifikasi_berkas || 0}
          subtitle="KTP & Lahan Perlu Dicek"
          icon={FileText}
          color="amber"
          badge="Antrean"
        />
        <KPICard
          title="Perlu Penugasan PPL"
          value={pendingAssignApps.length}
          subtitle="Berkas Lolos, Siap Survei"
          icon={UserCheck}
          color="blue"
          badge="Disposisi"
        />
        <KPICard
          title="Persetujuan Akhir"
          value={stats?.menunggu_persetujuan_akhir || 0}
          subtitle="Hasil Survei Lapangan Siap"
          icon={Award}
          color="purple"
          badge="Keputusan"
        />
        <KPICard
          title="Total Disetujui"
          value={stats?.disetujui || 0}
          subtitle="QR Terbit / Siap Diambil"
          icon={ShieldCheck}
          color="emerald"
          badge="Selesai"
        />
      </div>

      {/* Navigation Tabs */}
      <div className="flex border-b border-slate-200 overflow-x-auto gap-2">
        <button
          onClick={() => setActiveTab('verifikasi')}
          className={`pb-3 px-4 text-xs font-bold border-b-2 transition-colors flex items-center gap-2 whitespace-nowrap cursor-pointer ${
            activeTab === 'verifikasi'
              ? 'border-emerald-600 text-emerald-700'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <FileText className="w-4 h-4" />
          <span>1. Verifikasi Berkas</span>
          <span className="px-2 py-0.5 rounded-full text-[10px] bg-amber-100 text-amber-800">
            {pendingVerifyApps.length}
          </span>
        </button>

        <button
          onClick={() => setActiveTab('penugasan')}
          className={`pb-3 px-4 text-xs font-bold border-b-2 transition-colors flex items-center gap-2 whitespace-nowrap cursor-pointer ${
            activeTab === 'penugasan'
              ? 'border-emerald-600 text-emerald-700'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <UserCheck className="w-4 h-4" />
          <span>2. Penugasan PPL</span>
          <span className="px-2 py-0.5 rounded-full text-[10px] bg-blue-100 text-blue-800">
            {pendingAssignApps.length}
          </span>
        </button>

        <button
          onClick={() => setActiveTab('approval')}
          className={`pb-3 px-4 text-xs font-bold border-b-2 transition-colors flex items-center gap-2 whitespace-nowrap cursor-pointer ${
            activeTab === 'approval'
              ? 'border-emerald-600 text-emerald-700'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <Award className="w-4 h-4" />
          <span>3. Persetujuan Akhir</span>
          <span className="px-2 py-0.5 rounded-full text-[10px] bg-purple-100 text-purple-800">
            {pendingFinalApps.length}
          </span>
        </button>

        <button
          onClick={() => setActiveTab('audit')}
          className={`pb-3 px-4 text-xs font-bold border-b-2 transition-colors flex items-center gap-2 whitespace-nowrap cursor-pointer ${
            activeTab === 'audit'
              ? 'border-emerald-600 text-emerald-700'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>Audit Log Sistem ({auditLogs.length})</span>
        </button>
      </div>

      {/* TAB 1: VERIFIKASI BERKAS */}
      {activeTab === 'verifikasi' && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-slate-900">
              Antrean Pengajuan Menunggu Verifikasi Berkas ({pendingVerifyApps.length})
            </h3>
            <span className="text-xs text-slate-500">
              Periksa kecocokan foto KTP dan foto lahan sebelum meloloskan ke PPL
            </span>
          </div>

          {pendingVerifyApps.length === 0 ? (
            <div className="p-12 text-center bg-white rounded-2xl border border-slate-200">
              <Check className="w-10 h-10 text-emerald-500 mx-auto mb-2" />
              <p className="text-sm font-bold text-slate-800">Semua Berkas Telah Terverifikasi</p>
              <p className="text-xs text-slate-500 mt-1">Tidak ada antrean verifikasi berkas saat ini.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-6">
              {pendingVerifyApps.map((app) => (
                <div
                  key={app.id}
                  className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs hover:border-slate-300 transition-all space-y-5"
                >
                  {/* Top application details */}
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold text-slate-400">#{app.id}</span>
                        <h4 className="text-base font-bold text-slate-900">
                          {app.farmer?.nama} — Pengajuan {app.jumlah_diajukan} kg {app.fertilizer?.nama_pupuk}
                        </h4>
                      </div>
                      <p className="text-xs text-slate-500 mt-1 flex items-center gap-2">
                        <span>NIK: <strong className="font-mono text-slate-800">{app.farmer?.nik}</strong></span>
                        <span>•</span>
                        <span>Alamat KTP: {app.farmer?.alamat}</span>
                      </p>
                    </div>

                    <div className="flex items-center gap-2">
                      <StatusBadge status={app.status} />
                      <button
                        onClick={() => {
                          setSelectedApp(app);
                          setActionNotes('');
                          setShowVerifyModal(true);
                        }}
                        className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-sm shadow-emerald-200 flex items-center gap-1.5 cursor-pointer"
                      >
                        <ShieldCheck className="w-4 h-4" /> Proses Verifikasi
                      </button>
                    </div>
                  </div>

                  {/* SIDE-BY-SIDE VERIFICATION PHOTO PANEL */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Foto KTP Preview */}
                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center gap-1.5">
                          <FileText className="w-3.5 h-3.5 text-blue-600" />
                          Foto KTP Resmi Petani
                        </span>
                        <button
                          type="button"
                          onClick={() => setViewerPhoto({
                            isOpen: true,
                            title: `KTP: ${app.farmer?.nama}`,
                            url: app.foto_ktp_snapshot_url,
                            description: `NIK: ${app.farmer?.nik} | Alamat: ${app.farmer?.alamat}`
                          })}
                          className="text-[11px] text-emerald-700 hover:text-emerald-800 font-semibold flex items-center gap-1"
                        >
                          <Eye className="w-3.5 h-3.5" /> Perbesar
                        </button>
                      </div>

                      <div 
                        onClick={() => setViewerPhoto({
                          isOpen: true,
                          title: `KTP: ${app.farmer?.nama}`,
                          url: app.foto_ktp_snapshot_url,
                          description: `NIK: ${app.farmer?.nik} | Alamat: ${app.farmer?.alamat}`
                        })}
                        className="relative aspect-16/10 rounded-lg overflow-hidden bg-slate-200 border border-slate-300 cursor-pointer group"
                      >
                        <img
                          src={app.foto_ktp_snapshot_url}
                          alt="Foto KTP"
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                        />
                        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-xs font-semibold">
                          Klik untuk Perbesar
                        </div>
                      </div>

                      <div className="text-[11px] text-slate-600 space-y-0.5">
                        <p><strong>Nama:</strong> {app.farmer?.nama}</p>
                        <p><strong>NIK:</strong> {app.farmer?.nik}</p>
                        <p><strong>Domisili:</strong> {app.farmer?.alamat}</p>
                      </div>
                    </div>

                    {/* Foto Lahan Preview */}
                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center gap-1.5">
                          <Tractor className="w-3.5 h-3.5 text-emerald-600" />
                          Foto Lahan Pertanian
                        </span>
                        <button
                          type="button"
                          onClick={() => setViewerPhoto({
                            isOpen: true,
                            title: `Lahan: ${app.land?.lokasi_deskripsi}`,
                            url: app.foto_lahan_snapshot_url,
                            description: `Alamat: ${app.alamat_lahan} | Luas: ${app.land?.luas_m2} m² | Koordinat: ${app.latitude}, ${app.longitude}`
                          })}
                          className="text-[11px] text-emerald-700 hover:text-emerald-800 font-semibold flex items-center gap-1"
                        >
                          <Eye className="w-3.5 h-3.5" /> Perbesar
                        </button>
                      </div>

                      <div 
                        onClick={() => setViewerPhoto({
                          isOpen: true,
                          title: `Lahan: ${app.land?.lokasi_deskripsi}`,
                          url: app.foto_lahan_snapshot_url,
                          description: `Alamat: ${app.alamat_lahan} | Luas: ${app.land?.luas_m2} m² | Koordinat: ${app.latitude}, ${app.longitude}`
                        })}
                        className="relative aspect-16/10 rounded-lg overflow-hidden bg-slate-200 border border-slate-300 cursor-pointer group"
                      >
                        <img
                          src={app.foto_lahan_snapshot_url}
                          alt="Foto Lahan"
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                        />
                        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-xs font-semibold">
                          Klik untuk Perbesar
                        </div>
                      </div>

                      <div className="text-[11px] text-slate-600 space-y-0.5">
                        <p><strong>Lokasi:</strong> {app.alamat_lahan}</p>
                        <p><strong>Luas Tercatat:</strong> {app.land?.luas_m2} m²</p>
                        <p><strong>GPS:</strong> {app.latitude?.toFixed(4)}, {app.longitude?.toFixed(4)}</p>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 2: PENUGASAN PPL */}
      {activeTab === 'penugasan' && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-slate-900">
              Pengajuan Lolos Berkas — Siap Ditugaskan ke Petugas PPL ({pendingAssignApps.length})
            </h3>
            <span className="text-xs text-slate-500">
              Pilih petugas PPL sesuai wilayah binaan untuk survei fisik tanah dan tanaman
            </span>
          </div>

          {pendingAssignApps.length === 0 ? (
            <div className="p-12 text-center bg-white rounded-2xl border border-slate-200">
              <Check className="w-10 h-10 text-emerald-500 mx-auto mb-2" />
              <p className="text-sm font-bold text-slate-800">Semua Pengajuan Telah Ditugaskan ke PPL</p>
              <p className="text-xs text-slate-500 mt-1">Tidak ada berkas yang menunggu disposisi PPL.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {pendingAssignApps.map((app) => (
                <div
                  key={app.id}
                  className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4"
                >
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-xs font-bold text-slate-400">#{app.id}</span>
                      <h4 className="text-sm font-bold text-slate-900">
                        {app.farmer?.nama} ({app.farmer?.farmer_group?.nama_kelompok || 'Kelompok Tani'})
                      </h4>
                      <StatusBadge status={app.status} />
                    </div>
                    <p className="text-xs text-slate-600">
                      Alokasi: <strong className="text-slate-800">{app.jumlah_diajukan} kg {app.fertilizer?.nama_pupuk}</strong> | 
                      Lahan: {app.land?.lokasi_deskripsi} ({app.land?.luas_m2} m²)
                    </p>
                    <p className="text-xs text-slate-500 flex items-center gap-1">
                      <MapPin className="w-3.5 h-3.5 text-slate-400" />
                      {app.alamat_lahan}
                    </p>
                  </div>

                  <button
                    onClick={() => {
                      setSelectedApp(app);
                      setActionNotes('');
                      setShowAssignModal(true);
                    }}
                    className="px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-sm shadow-blue-200 cursor-pointer shrink-0"
                  >
                    <UserCheck className="w-4 h-4" />
                    <span>Tugaskan PPL</span>
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 3: PERSETUJUAN AKHIR */}
      {activeTab === 'approval' && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-slate-900">
              Hasil Survei Lapangan PPL Menunggu Keputusan Akhir ({pendingFinalApps.length})
            </h3>
            <span className="text-xs text-slate-500">
              Tinjau rekomendasi dan bukti foto survei PPL sebelum menerbitkan kuota pupuk
            </span>
          </div>

          {pendingFinalApps.length === 0 ? (
            <div className="p-12 text-center bg-white rounded-2xl border border-slate-200">
              <Check className="w-10 h-10 text-emerald-500 mx-auto mb-2" />
              <p className="text-sm font-bold text-slate-800">Tidak Ada Antrean Persetujuan Akhir</p>
              <p className="text-xs text-slate-500 mt-1">Semua survei PPL telah diputuskan.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-6">
              {pendingFinalApps.map((app) => (
                <div
                  key={app.id}
                  className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-5"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold text-slate-400">#{app.id}</span>
                        <h4 className="text-base font-bold text-slate-900">
                          {app.farmer?.nama} — Pengajuan {app.jumlah_diajukan} kg {app.fertilizer?.nama_pupuk}
                        </h4>
                      </div>
                      <p className="text-xs text-slate-500 mt-0.5">
                        Lahan: {app.land?.lokasi_deskripsi} | Alamat: {app.alamat_lahan}
                      </p>
                    </div>

                    <div className="flex items-center gap-2">
                      <StatusBadge status={app.status} />
                      <button
                        onClick={() => {
                          setSelectedApp(app);
                          setActionNotes('');
                          setApprovedKg(app.jumlah_diajukan);
                          setShowFinalModal(true);
                        }}
                        className="px-4 py-2 rounded-xl bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-sm shadow-purple-200 cursor-pointer"
                      >
                        <Award className="w-4 h-4" /> Beri Keputusan Akhir
                      </button>
                    </div>
                  </div>

                  {/* Detailed PPL Survey Results Box */}
                  {app.survey ? (
                    <div className="bg-purple-50/50 rounded-xl p-4 border border-purple-200 space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-bold text-purple-900 uppercase tracking-wider flex items-center gap-1.5">
                          <ShieldCheck className="w-4 h-4 text-purple-600" />
                          Laporan Survei Fisik Petugas PPL
                        </span>
                        <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${
                          app.survey.rekomendasi === 'SETUJU'
                            ? 'bg-emerald-100 text-emerald-800'
                            : 'bg-rose-100 text-rose-800'
                        }`}>
                          Rekomendasi PPL: {app.survey.rekomendasi}
                        </span>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
                        <div>
                          <span className="text-slate-500 block text-[11px]">Kondisi Fisik Lahan</span>
                          <span className="font-bold text-slate-800">{app.survey.kondisi_fisik_lahan}</span>
                          {app.survey.keterangan_fisik_lahan && (
                            <p className="text-[11px] text-slate-500 mt-0.5">{app.survey.keterangan_fisik_lahan}</p>
                          )}
                        </div>

                        <div>
                          <span className="text-slate-500 block text-[11px]">Kesesuaian Tanaman</span>
                          <span className="font-bold text-slate-800">{app.survey.kondisi_tanaman}</span>
                          {app.survey.keterangan_tanaman && (
                            <p className="text-[11px] text-slate-500 mt-0.5">{app.survey.keterangan_tanaman}</p>
                          )}
                        </div>

                        <div>
                          <span className="text-slate-500 block text-[11px]">Luas Aktual Terukur</span>
                          <span className="font-bold text-slate-800">{app.survey.luas_lahan_aktual_m2 || app.land?.luas_m2} m²</span>
                        </div>
                      </div>

                      {app.survey.catatan_ppl && (
                        <div className="text-xs text-slate-700 bg-white/80 p-2.5 rounded-lg border border-purple-100 italic">
                          "{app.survey.catatan_ppl}"
                        </div>
                      )}

                      {/* Survey Photo Attachment */}
                      {app.survey.foto_survei_urls?.[0] && (
                        <div>
                          <span className="text-[11px] font-semibold text-slate-500 block mb-1.5">
                            Dokumentasi Foto Survei Lapangan:
                          </span>
                          <div 
                            onClick={() => setViewerPhoto({
                              isOpen: true,
                              title: `Dokumentasi Survei Lapangan PPL #${app.id}`,
                              url: app.survey.foto_survei_urls[0],
                              description: `Petugas PPL: Survei fisik kondisi tanah & tanaman`
                            })}
                            className="w-40 h-24 rounded-lg overflow-hidden border border-purple-200 bg-slate-200 cursor-pointer relative group"
                          >
                            <img
                              src={app.survey.foto_survei_urls[0]}
                              alt="Survei Lapangan"
                              className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                            />
                            <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-[11px] font-semibold">
                              Perbesar Foto
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="text-xs text-slate-400 italic">Data survei belum lengkap.</div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 4: AUDIT LOG */}
      {activeTab === 'audit' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div>
              <h3 className="text-sm font-bold text-slate-900">
                Catatan Jejak Keamanan & Akses Sistem (Audit Logs)
              </h3>
              <p className="text-xs text-slate-500 mt-0.5">
                Mencatat setiap tindakan penting, termasuk pembukaan file KTP dan perubahan status pengajuan
              </p>
            </div>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-slate-100 text-slate-600">
              50 Tindakan Terakhir
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 font-semibold uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="py-2.5 px-3">Waktu</th>
                  <th className="py-2.5 px-3">Aksi</th>
                  <th className="py-2.5 px-3">Resource</th>
                  <th className="py-2.5 px-3">Keterangan</th>
                  <th className="py-2.5 px-3">IP Address</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-slate-700">
                {auditLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50/50">
                    <td className="py-2.5 px-3 font-mono text-[11px] text-slate-400">
                      {new Date(log.created_at).toLocaleString('id-ID')}
                    </td>
                    <td className="py-2.5 px-3 font-bold text-slate-900">
                      <span className="px-2 py-0.5 rounded-md bg-slate-100 font-mono text-[10px]">
                        {log.action}
                      </span>
                    </td>
                    <td className="py-2.5 px-3 font-semibold text-emerald-800">
                      {log.resource} #{log.resource_id || ''}
                    </td>
                    <td className="py-2.5 px-3 text-slate-600 max-w-xs truncate">
                      {log.details || '-'}
                    </td>
                    <td className="py-2.5 px-3 font-mono text-[11px] text-slate-400">
                      {log.ip_address || '127.0.0.1'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Modal: Verifikasi Berkas (Approve / Perbaikan / Tolak) */}
      {showVerifyModal && selectedApp && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-lg w-full overflow-hidden p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">
                Keputusan Verifikasi Berkas #{selectedApp.id}
              </h3>
              <button
                onClick={() => setShowVerifyModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <p className="text-xs text-slate-600">
              Pemohon: <strong className="text-slate-900">{selectedApp.farmer?.nama}</strong> | NIK: {selectedApp.farmer?.nik}
            </p>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Catatan Verifikasi Admin (Wajib jika Perbaikan / Tolak):
              </label>
              <textarea
                rows={3}
                value={actionNotes}
                onChange={(e) => setActionNotes(e.target.value)}
                placeholder="Contoh: Foto KTP sedikit buram pada bagian NIK, mohon upload ulang foto asli..."
                className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden"
              />
            </div>

            <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowVerifyModal(false)}
                className="px-3 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={() => handleVerify('TOLAK')}
                className="px-3 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs cursor-pointer"
              >
                Tolak Berkas
              </button>
              <button
                type="button"
                onClick={() => handleVerify('PERBAIKAN')}
                className="px-3 py-2 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs cursor-pointer"
              >
                Minta Perbaikan
              </button>
              <button
                type="button"
                onClick={() => handleVerify('APPROVE')}
                className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs cursor-pointer shadow-sm shadow-emerald-200"
              >
                Setujui Berkas
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Penugasan PPL */}
      {showAssignModal && selectedApp && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-md w-full overflow-hidden p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">
                Penugasan PPL untuk Pengajuan #{selectedApp.id}
              </h3>
              <button
                onClick={() => setShowAssignModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Pilih Petugas PPL Lapangan:
              </label>
              <select
                value={selectedPplId}
                onChange={(e) => setSelectedPplId(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-blue-500 outline-hidden font-semibold"
              >
                {pplOfficers.map((ppl) => (
                  <option key={ppl.id} value={ppl.id}>
                    {ppl.username} ({ppl.email}) — Tugas Aktif: {ppl.active_tasks}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Instruksi Khusus untuk PPL:
              </label>
              <textarea
                rows={3}
                value={actionNotes}
                onChange={(e) => setActionNotes(e.target.value)}
                placeholder="Contoh: Cek batas patok tanah dan pastikan komoditas sesuai musim tanam..."
                className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-blue-500 outline-hidden"
              />
            </div>

            <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowAssignModal(false)}
                className="px-3 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleAssignPPL}
                className="px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs cursor-pointer shadow-sm shadow-blue-200"
              >
                Kirim Penugasan
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Keputusan Akhir (Final Approval) */}
      {showFinalModal && selectedApp && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-md w-full overflow-hidden p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">
                Persetujuan Akhir Pengajuan #{selectedApp.id}
              </h3>
              <button
                onClick={() => setShowFinalModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Alokasi Jumlah Pupuk Disetujui (kg):
              </label>
              <input
                type="number"
                value={approvedKg}
                onChange={(e) => setApprovedKg(e.target.value)}
                className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-900 focus:border-purple-500 outline-hidden"
              />
              <span className="text-[10px] text-slate-400 mt-0.5 block">
                Permintaan awal: {selectedApp.jumlah_diajukan} kg
              </span>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Catatan Keputusan Final:
              </label>
              <textarea
                rows={3}
                value={actionNotes}
                onChange={(e) => setActionNotes(e.target.value)}
                placeholder="Catatan persetujuan dinas pertanian..."
                className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-purple-500 outline-hidden"
              />
            </div>

            <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowFinalModal(false)}
                className="px-3 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={() => handleFinalApprove('REJECT')}
                className="px-3 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs cursor-pointer"
              >
                Tolak Pengajuan
              </button>
              <button
                type="button"
                onClick={() => handleFinalApprove('APPROVE')}
                className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs cursor-pointer shadow-sm shadow-emerald-200"
              >
                Setujui & Terbitkan QR
              </button>
            </div>
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
