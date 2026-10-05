import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { 
  ShieldCheck, UserCheck, Award, FileText, Check, X,
  Eye, MapPin, Tractor, Plus, SlidersHorizontal,
  RefreshCw, ShieldAlert, Users, LandPlot,
  PackageCheck, BarChart3, ClipboardList, UserCog, Database,
  Search, LayoutGrid, History, TrendingUp
} from 'lucide-react';
import toast from 'react-hot-toast';
import { adminApi, applicationsApi, farmersApi, landsApi } from '../services/api';
import KPICard from '../components/KPICard';
import StatusBadge from '../components/StatusBadge';
import ProgressStepper from '../components/ProgressStepper';
import PhotoViewerModal from '../components/PhotoViewerModal';
import { formatCoord } from '../utils/format';

const ADMIN_TAB_PATHS = {
  dashboard: '/admin',
  verifikasi: '/admin/verifikasi',
  penugasan: '/admin/penugasan',
  approval: '/admin/approval',
  petani: '/admin/petani',
  lahan: '/admin/lahan',
  monitoring: '/admin/monitoring',
  laporan: '/admin/laporan',
  pengguna: '/admin/pengguna',
  audit: '/admin/audit',
};
const ADMIN_ROUTE_TABS = Object.fromEntries(
  Object.entries(ADMIN_TAB_PATHS).map(([tab, path]) => [path, tab])
);

export default function AdminDashboard() {
  const location = useLocation();
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [applications, setApplications] = useState([]);
  const [pplOfficers, setPplOfficers] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [farmersList, setFarmersList] = useState([]);
  const [landsList, setLandsList] = useState([]);
  const [loading, setLoading] = useState(true);

  // Selected item for actions
  const [selectedApp, setSelectedApp] = useState(null);
  const [actionNotes, setActionNotes] = useState('');
  const [selectedPplId, setSelectedPplId] = useState('');
  const [approvedKg, setApprovedKg] = useState('');
  const [selectedFarmerDetail, setSelectedFarmerDetail] = useState(null);
  const [selectedLandDetail, setSelectedLandDetail] = useState(null);

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
  const currentPath = location.pathname.replace(/\/+$/, '') || '/admin';
  const activeTab = ADMIN_ROUTE_TABS[currentPath] || 'dashboard';

  const fetchData = async () => {
    setLoading(true);
    try {
      const [sRes, aRes, pRes, lRes, fRes, landRes] = await Promise.all([
        adminApi.getStats(),
        applicationsApi.getAll(),
        adminApi.getPplOfficers(),
        adminApi.getAuditLogs(),
        farmersApi.getAll(),
        landsApi.getAll(),
      ]);

      const applicationsData = Array.isArray(aRes?.data) ? aRes.data : [];
      const pplData = Array.isArray(pRes?.data) ? pRes.data : [];
      const auditData = Array.isArray(lRes?.data) ? lRes.data : [];
      const farmerData = Array.isArray(fRes?.data) ? fRes.data : [];
      const landData = Array.isArray(landRes?.data) ? landRes.data : [];

      setStats(sRes?.data || {});
      setApplications(applicationsData);
      setPplOfficers(pplData);
      setAuditLogs(auditData);
      setFarmersList(farmerData);
      setLandsList(landData);

      if (pplData.length > 0) {
        setSelectedPplId(String(pplData[0].id));
      } else {
        setSelectedPplId('');
      }
    } catch (e) {
      console.error('Error fetching admin data:', e);
      toast.error('Gagal memuat data Admin dari server.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    const applicationId = new URLSearchParams(location.search).get('applicationId');
    if (!applicationId || loading) return;

    const app = applications.find((item) => String(item.id) === applicationId);
    const eligibleStatuses = {
      verifikasi: ['DIAJUKAN', 'MENUNGGU_VERIFIKASI_BERKAS'],
      penugasan: ['BERKAS_TERVERIFIKASI'],
      approval: ['MENUNGGU_PERSETUJUAN_AKHIR'],
    }[activeTab];
    if (!app || !eligibleStatuses?.includes(app.status)) {
      toast.error('Pengajuan tidak ditemukan pada antrean yang dipilih.');
      navigate(currentPath, { replace: true });
      return;
    }

    setSelectedApp(app);
    setActionNotes('');
    if (activeTab === 'verifikasi') setShowVerifyModal(true);
    if (activeTab === 'penugasan') setShowAssignModal(true);
    if (activeTab === 'approval') {
      setApprovedKg(String(app.jumlah_diajukan || ''));
      setShowFinalModal(true);
    }
    navigate(currentPath, { replace: true });
  }, [activeTab, applications, currentPath, loading, location.search, navigate]);

  // Filter applications by tab
  const pendingVerifyApps = applications.filter((a) =>
    ['DIAJUKAN', 'MENUNGGU_VERIFIKASI_BERKAS'].includes(a.status)
  );
  const pendingAssignApps = applications.filter((a) =>
    ['BERKAS_TERVERIFIKASI'].includes(a.status)
  );
  const assignmentApps = applications.filter((a) =>
    ['BERKAS_TERVERIFIKASI', 'DITUGASKAN_KE_PPL', 'SURVEI_LAPANGAN', 'MENUNGGU_PERSETUJUAN_AKHIR'].includes(a.status)
  );
  const pendingFinalApps = applications.filter((a) =>
    ['MENUNGGU_PERSETUJUAN_AKHIR'].includes(a.status)
  );
  const approvedApps = applications.filter((a) =>
    ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].includes(a.status)
  );
  const rejectedApps = applications.filter((a) =>
    ['DITOLAK_BERKAS', 'DITOLAK_LAPANGAN'].includes(a.status)
  );
  const completedVerificationApps = applications.filter((a) =>
    ['BERKAS_TERVERIFIKASI', 'DITUGASKAN_KE_PPL', 'SURVEI_LAPANGAN', 'MENUNGGU_PERSETUJUAN_AKHIR', 'DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].includes(a.status)
  );
  const verificationDurations = applications
    .filter((app) => app.admin_verified_at && app.tanggal_pengajuan)
    .map((app) => new Date(app.admin_verified_at).getTime() - new Date(app.tanggal_pengajuan).getTime())
    .filter((duration) => duration >= 0);
  const averageVerificationHours = verificationDurations.length
    ? verificationDurations.reduce((total, duration) => total + duration, 0) / verificationDurations.length / (1000 * 60 * 60)
    : null;
  const highWorkloadPplCount = pplOfficers.filter((officer) => Number(officer.active_tasks || 0) > 8).length;
  const assignmentsToday = assignmentApps.filter((app) => {
    if (!app.assigned_at) return false;
    const assignedAt = new Date(app.assigned_at);
    const today = new Date();
    return assignedAt.toDateString() === today.toDateString();
  }).length;
  const totalApprovedKg = approvedApps.reduce(
    (total, app) => total + Number(app.jumlah_disetujui || app.jumlah_diajukan || 0),
    0
  );
  const uniqueFarmers = farmersList;
  const uniqueLands = landsList;
  const totalLandAreaM2 = uniqueLands.reduce((total, land) => total + Number(land.luas_m2 || 0), 0);
  const farmersWithoutGroup = uniqueFarmers.filter((farmer) => !farmer.farmer_group_id).length;
  const landsAwaitingSurvey = uniqueLands.filter((land) =>
    applications.some((app) =>
      app.land_id === land.id && ['DITUGASKAN_KE_PPL', 'SURVEI_LAPANGAN'].includes(app.status)
    )
  ).length;
  const adminMenu = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutGrid },
    { id: 'verifikasi', label: 'Verifikasi Berkas', icon: FileText, count: pendingVerifyApps.length },
    { id: 'penugasan', label: 'Penugasan PPL', icon: UserCheck, count: pendingAssignApps.length },
    { id: 'approval', label: 'Persetujuan Akhir', icon: Award, count: pendingFinalApps.length },
    { id: 'petani', label: 'Data Petani', icon: Users },
    { id: 'lahan', label: 'Data Lahan', icon: LandPlot },
    { id: 'monitoring', label: 'Monitoring', icon: BarChart3 },
    { id: 'laporan', label: 'Laporan', icon: ClipboardList },
    { id: 'pengguna', label: 'Manajemen Pengguna', icon: UserCog },
    { id: 'audit', label: 'Audit Log', icon: History },
  ];
  const navigateToAdminTab = (tab, applicationId) => {
    const path = ADMIN_TAB_PATHS[tab];
    if (!path) return;
    navigate(applicationId ? `${path}?applicationId=${applicationId}` : path);
  };

  // Verification Actions
  const handleVerify = async (action) => {
    if (!selectedApp) return;
    const toastId = toast.loading('Memproses verifikasi berkas...');
    try {
      await adminApi.verifyDocs(selectedApp.id, {
        action,
        catatan: actionNotes,
      });
      setShowVerifyModal(false);
      setActionNotes('');
      await fetchData();
      toast.success(`Berkas pengajuan #${selectedApp.id} berhasil diproses: ${action}`, { id: toastId });
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal memproses verifikasi berkas.', { id: toastId });
    }
  };

  // PPL Assignment Action
  const handleAssignPPL = async () => {
    if (!selectedApp || !selectedPplId) return;
    const toastId = toast.loading('Menugaskan petugas PPL...');
    try {
      await adminApi.assignPpl(selectedApp.id, {
        ppl_id: parseInt(selectedPplId),
        catatan: actionNotes,
      });
      setShowAssignModal(false);
      setActionNotes('');
      await fetchData();
      toast.success(`Petugas PPL berhasil ditugaskan untuk pengajuan #${selectedApp.id}!`, { id: toastId });
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal menugaskan PPL.', { id: toastId });
    }
  };

  // Final Approval Action
  const handleFinalApprove = async (action) => {
    if (!selectedApp) return;
    const toastId = toast.loading('Menyimpan keputusan akhir...');
    try {
      const parsedKg = approvedKg !== '' && approvedKg !== null && approvedKg !== undefined
        ? parseFloat(String(approvedKg).replace(',', '.'))
        : null;

      await adminApi.finalApprove(selectedApp.id, {
        action,
        jumlah_disetujui: parsedKg,
        catatan: actionNotes,
      });
      setShowFinalModal(false);
      setActionNotes('');
      setApprovedKg('');
      await fetchData();
      toast.success(
        action === 'APPROVE'
          ? `✅ Pengajuan #${selectedApp.id} disetujui. Alokasi pupuk siap digunakan melalui QR pada karung.`
          : `❌ Pengajuan #${selectedApp.id} ditolak.`,
        { id: toastId, duration: 5000 }
      );
    } catch (err) {
      const errorMsg = typeof err.response?.data?.detail === 'string'
        ? err.response.data.detail
        : (Array.isArray(err.response?.data?.detail)
          ? err.response.data.detail.map((e) => e.msg).join(', ')
          : 'Gagal menyimpan keputusan akhir.');
      toast.error(errorMsg, { id: toastId });
    }
  };

  const dashboardQueues = [
    {
      id: 'verifikasi',
      title: 'Verifikasi Berkas',
      description: 'Pengajuan yang menunggu pemeriksaan dokumen.',
      apps: pendingVerifyApps,
      actionLabel: 'Periksa Berkas',
      statusLabel: (app) => app.status === 'DIAJUKAN' ? 'Diajukan' : 'Menunggu Verifikasi',
      statusClass: 'bg-amber-50 text-amber-700 border-amber-200',
      onAction: (app) => {
        navigateToAdminTab('verifikasi', app.id);
      },
    },
    {
      id: 'penugasan',
      title: 'Penugasan PPL',
      description: 'Berkas terverifikasi yang siap ditugaskan kepada PPL.',
      apps: pendingAssignApps,
      actionLabel: 'Tugaskan PPL',
      statusLabel: () => 'Siap Ditugaskan',
      statusClass: 'bg-blue-50 text-blue-700 border-blue-200',
      onAction: (app) => {
        navigateToAdminTab('penugasan', app.id);
      },
    },
    {
      id: 'approval',
      title: 'Persetujuan Akhir',
      description: 'Hasil survei PPL yang menunggu keputusan akhir.',
      apps: pendingFinalApps,
      actionLabel: 'Proses Keputusan',
      statusLabel: () => 'Menunggu Persetujuan',
      statusClass: 'bg-purple-50 text-purple-700 border-purple-200',
      onAction: (app) => {
        navigateToAdminTab('approval', app.id);
      },
    },
  ];

  if (loading) {
    return (
      <div className="space-y-8 pb-16 animate-pulse">
        <div className="rounded-3xl bg-slate-200 h-32" />
        <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
          {[...Array(5)].map((_, i) => <div key={i} className="h-28 bg-slate-200 rounded-2xl" />)}
        </div>
        <div className="h-48 bg-slate-200 rounded-2xl" />
      </div>
    );
  }

  return (
    <div className="flex flex-col lg:flex-row gap-6 pb-16">
      <aside className="hidden lg:flex lg:w-60 shrink-0 flex-col self-start sticky top-24 bg-white border border-slate-200/90 rounded-2xl p-3.5 shadow-xs">
        <div className="px-3 py-2 mb-2 border-b border-slate-100">
          <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-slate-400">RUANG KERJA</p>
          <p className="text-sm font-black text-slate-900 mt-0.5 mb-1">Admin Dinas</p>
        </div>
        <nav className="space-y-4" aria-label="Navigasi admin">
          {[
            ['UTAMA', ['dashboard']],
            ['PENGAJUAN', ['verifikasi', 'penugasan', 'approval']],
            ['DATA', ['petani', 'lahan']],
            ['MONITORING', ['monitoring', 'laporan']],
            ['SISTEM', ['pengguna', 'audit']],
          ].map(([group, itemIds]) => (
            <div key={group}>
              <p className="px-3 mb-1 text-[10px] font-bold tracking-[0.14em] text-slate-400 uppercase">{group}</p>
              <div className="space-y-0.5">
                {adminMenu.filter((item) => itemIds.includes(item.id)).map((item) => {
                  const Icon = item.icon;
                  const isActive = activeTab === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => navigateToAdminTab(item.id)}
                      className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-bold text-left transition-colors cursor-pointer ${
                        isActive ? 'bg-emerald-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                      }`}
                    >
                      <Icon className="w-4 h-4 shrink-0" />
                      <span className="truncate">{item.label}</span>
                      {item.count !== undefined && (
                        <span className={`ml-auto text-xs font-medium ${isActive ? 'text-emerald-100' : 'text-slate-400'}`}>
                          {item.count}
                        </span>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>
      </aside>

      <div className="min-w-0 flex-1 space-y-6">
        <div className="lg:hidden">
          <label htmlFor="admin-section" className="sr-only">Bagian dashboard admin</label>
          <select id="admin-section" value={activeTab} onChange={(event) => navigateToAdminTab(event.target.value)} className="w-full px-3 py-2.5 rounded-xl border border-slate-300 bg-white text-xs font-bold text-slate-700 outline-hidden focus:border-emerald-500">
            {adminMenu.map((item) => <option key={item.id} value={item.id}>{item.label}</option>)}
          </select>
        </div>

        {/* ========================================================= */}
        {/* 1. TAB: DASHBOARD                                         */}
        {/* ========================================================= */}
        {activeTab === 'dashboard' && (
          <div className="space-y-6">
            {/* Dashboard Hero Banner */}
            <div className="rounded-2xl bg-slate-950 text-white p-6 sm:p-7 relative overflow-hidden shadow-xs border border-slate-800">
              <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                  <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                    <ShieldAlert className="w-4 h-4 text-emerald-400 stroke-[2.2]" /> PUSAT PENGELOLAAN SUBSIDI
                  </div>
                  <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
                    Dashboard Admin Dinas
                  </h1>
                  <p className="mt-1 text-xs sm:text-sm text-slate-400 max-w-2xl leading-relaxed">
                    Kelola verifikasi pengajuan, penugasan PPL, persetujuan pupuk, dan monitoring distribusi.
                  </p>
                </div>

                <button
                  onClick={fetchData}
                  className="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-200 text-xs font-bold border border-slate-700/80 transition-colors shrink-0 cursor-pointer shadow-xs"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
                  <span>Segarkan Data</span>
                </button>
              </div>
            </div>

            {/* 5 KPI Cards */}
            <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-5 gap-3 sm:gap-3.5">
              <KPICard
                title="MENUNGGU VERIFIKASI"
                value={pendingVerifyApps.length}
                subtitle={stats?.menunggu_verifikasi_berkas ? `${stats.menunggu_verifikasi_berkas} antrean aktif` : 'KTP & lahan belum valid'}
                icon={FileText}
                color="amber"
                badge="Antrean"
              />
              <KPICard
                title="PERLU PENUGASAN PPL"
                value={pendingAssignApps.length}
                subtitle={stats?.perlu_survei_ppl ? `${stats.perlu_survei_ppl} menunggu disposisi` : 'Berkas siap ditugaskan'}
                icon={UserCheck}
                color="blue"
                badge="Disposisi"
              />
              <KPICard
                title="MENUNGGU PERSETUJUAN"
                value={pendingFinalApps.length}
                subtitle={stats?.menunggu_persetujuan_akhir ? `${stats.menunggu_persetujuan_akhir} keputusan menunggu` : 'Hasil survei menunggu review'}
                icon={Award}
                color="purple"
                badge="Keputusan"
              />
              <KPICard
                title="TOTAL DISETUJUI"
                value={approvedApps.length}
                subtitle={stats?.disetujui ? `${stats.disetujui} aplikasi disetujui` : 'Alokasi pupuk berjalan'}
                icon={TrendingUp}
                color="emerald"
                badge="Selesai"
              />
              <KPICard
                title="TOTAL DITOLAK"
                value={stats?.ditolak ?? 0}
                subtitle={stats?.ditolak ? `${stats.ditolak} pengajuan ditolak` : 'Berkas tidak ada penolakan'}
                icon={ShieldAlert}
                color="rose"
                badge="Ditolak"
              />
            </div>

            <div className="space-y-5">
              {dashboardQueues.map((queue) => (
                <section key={queue.id} className="bg-white rounded-2xl border border-slate-200/90 shadow-xs overflow-hidden">
                  <div className="p-5 sm:p-6 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                    <div>
                      <h3 className="text-base font-bold text-slate-900">{queue.title}</h3>
                      <p className="text-xs text-slate-400 mt-0.5">{queue.description}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="bg-slate-100 text-slate-600 font-semibold text-xs px-2.5 py-1 rounded-full">
                        {queue.apps.length} pengajuan
                      </span>
                      <button
                        type="button"
                        onClick={() => navigateToAdminTab(queue.id)}
                        className="text-xs font-bold text-emerald-700 hover:text-emerald-800 cursor-pointer"
                      >
                        Lihat semua
                      </button>
                    </div>
                  </div>

                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-50/80 text-slate-400 uppercase text-[10px] font-bold tracking-wider border-b border-slate-100">
                        <tr>
                          <th className="py-3 px-4">NO. PENGAJUAN</th>
                          <th className="py-3 px-4">PETANI</th>
                          <th className="py-3 px-4">LOKASI LAHAN</th>
                          <th className="py-3 px-4">PUPUK DIAJUKAN</th>
                          <th className="py-3 px-4">STATUS</th>
                          <th className="py-3 px-4 text-center">AKSI</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100 text-slate-700">
                        {queue.apps.map((app) => (
                          <tr key={app.id} className="hover:bg-slate-50/60 transition-colors">
                            <td className="py-3.5 px-4 font-mono font-bold text-slate-900">#{app.id}</td>
                            <td className="py-3.5 px-4">
                              <span className="block font-bold text-slate-900">{app.farmer?.nama || 'Petani'}</span>
                              {app.farmer?.nik && <span className="text-[11px] text-slate-400">NIK: {app.farmer.nik}</span>}
                            </td>
                            <td className="py-3.5 px-4 text-slate-600">
                              {app.land?.lokasi_deskripsi || app.alamat_lahan || '—'}
                            </td>
                            <td className="py-3.5 px-4">
                              <span className="block font-semibold text-slate-800">{app.fertilizer?.nama_pupuk || 'Pupuk'}</span>
                              <span className="text-[11px] text-slate-400">
                                {Number(app.jumlah_diajukan || 0).toLocaleString('id-ID', { maximumFractionDigits: 2 })} kg
                              </span>
                            </td>
                            <td className="py-3.5 px-4">
                              <span className={`inline-block px-2.5 py-0.5 rounded-full text-[11px] font-semibold border ${queue.statusClass}`}>
                                {queue.statusLabel(app)}
                              </span>
                            </td>
                            <td className="py-3.5 px-4 text-center">
                              <button
                                type="button"
                                onClick={() => queue.onAction(app)}
                                className="px-3.5 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-xs transition-colors cursor-pointer whitespace-nowrap"
                              >
                                {queue.actionLabel}
                              </button>
                            </td>
                          </tr>
                        ))}
                        {queue.apps.length === 0 && (
                          <tr>
                            <td colSpan={6} className="py-8 px-4 text-center text-xs text-slate-400">
                              Tidak ada pengajuan yang menunggu {queue.title.toLowerCase()}.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </section>
              ))}
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 2. TAB: VERIFIKASI BERKAS                                 */}
        {/* ========================================================= */}
        {activeTab === 'verifikasi' && (
          <div className="space-y-6">
            {/* Hero Banner */}
            <div className="rounded-2xl bg-slate-950 text-white p-6 sm:p-7 relative overflow-hidden shadow-xs border border-slate-800">
              <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                  <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                    <FileText className="w-4 h-4 text-emerald-400 stroke-[2.2]" /> VERIFIKASI TAHAP AWAL
                  </div>
                  <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
                    Verifikasi Berkas
                  </h1>
                  <p className="mt-1 text-xs sm:text-sm text-slate-400 leading-relaxed">
                    Periksa kelengkapan identitas, bukti lahan, dan dokumen pengajuan sebelum diteruskan ke penugasan PPL.
                  </p>
                </div>
              </div>
            </div>

            {/* 4 KPI Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-3.5">
              <KPICard
                title="MENUNGGU VERIFIKASI"
                value={pendingVerifyApps.length}
                subtitle="Antrean dari pengajuan backend"
                icon={FileText}
                color="amber"
                badge="Perlu Tindakan"
              />
              <KPICard
                title="BERKAS LENGKAP"
                value={completedVerificationApps.length}
                subtitle="Lolos verifikasi berkas"
                icon={PackageCheck}
                color="emerald"
                badge="Lolos"
              />
              <KPICard
                title="PERLU PERBAIKAN"
                value={applications.filter((app) => app.status === 'PERLU_PERBAIKAN_BERKAS').length}
                subtitle="Menunggu revisi Petani"
                icon={ShieldAlert}
                color="rose"
                badge="Revisi"
              />
              <KPICard
                title="RATA-RATA PROSES"
                value={averageVerificationHours == null ? '—' : `${averageVerificationHours.toLocaleString('id-ID', { maximumFractionDigits: 1 })}j`}
                subtitle={averageVerificationHours == null ? 'Data waktu proses belum tersedia' : 'Rata-rata sejak pengajuan'}
                icon={History}
                color="blue"
                badge="SLA"
              />
            </div>

            {/* Filter Bar */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
              <div className="relative flex-1">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Cari nomor pengajuan, NIK, atau nama petani..."
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-hidden focus:border-emerald-500 shadow-2xs"
                />
              </div>
              <div className="flex items-center gap-2">
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Semua Status</option>
                  <option>Menunggu Verifikasi</option>
                  <option>Perlu Perbaikan</option>
                  <option>Lengkap</option>
                </select>
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Semua Kecamatan</option>
                  <option>Trowulan</option>
                  <option>Mojosari</option>
                  <option>Puri</option>
                  <option>Dlanggu</option>
                  <option>Sooko</option>
                </select>
                <button
                  type="button"
                  className="p-2.5 bg-white border border-slate-200/90 hover:bg-slate-50 text-slate-600 rounded-xl shadow-2xs cursor-pointer"
                  title="Filter Lanjutan"
                >
                  <SlidersHorizontal className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Data Table: Antrean Verifikasi Berkas */}
            <div className="bg-white rounded-2xl border border-slate-200/90 shadow-xs overflow-hidden">
              <div className="p-5 sm:p-6 border-b border-slate-100 flex items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Antrean Verifikasi Berkas</h3>
                  <p className="text-xs text-slate-400 mt-0.5">Daftar berkas pengajuan subsidi yang menunggu pemeriksaan dokumen dan kepemilikan lahan.</p>
                </div>
                <span className="bg-blue-50 text-blue-600 font-semibold text-xs px-2.5 py-1 rounded-full border border-blue-100/80 shrink-0">
                  {pendingVerifyApps.length} ditampilkan
                </span>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50/80 text-slate-400 uppercase text-[10px] font-bold tracking-wider border-b border-slate-100">
                    <tr>
                      <th className="py-3 px-4">NO. PENGAJUAN</th>
                      <th className="py-3 px-4">PETANI / POKTAN</th>
                      <th className="py-3 px-4">LOKASI</th>
                      <th className="py-3 px-4">DOKUMEN</th>
                      <th className="py-3 px-4">STATUS</th>
                      <th className="py-3 px-4 text-center">AKSI</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {pendingVerifyApps.map((app) => {
                      const ktpUrl = app.foto_ktp_snapshot_url || app.farmer?.foto_ktp_url;
                      const landPhotoUrl = app.foto_lahan_snapshot_url || app.land?.foto_lahan_url;
                      const statusLabel = app.status === 'DIAJUKAN' ? 'Diajukan' : 'Menunggu Verifikasi';
                      return (
                      <tr key={app.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3.5 px-4 font-mono">
                          <span className="font-bold text-slate-900 block">#{app.id}</span>
                          <span className="text-[10px] text-slate-400 font-sans">{new Date(app.tanggal_pengajuan).toLocaleString('id-ID')}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <strong className="block text-slate-900 font-bold">{app.farmer?.nama || 'Belum tersedia'}</strong>
                          <span className="text-[11px] text-slate-400">NIK: {app.farmer?.nik || 'Belum tersedia'} • {app.farmer?.farmer_group?.nama_kelompok || 'Poktan belum tersedia'}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="text-slate-800 font-medium block">{app.land?.lokasi_deskripsi || app.alamat_lahan || app.land?.alamat_lahan || 'Lokasi belum tersedia'}</span>
                          <span className="text-[11px] text-slate-400">{app.land?.alamat_lahan || 'Alamat lahan belum tersedia'}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-slate-100 text-slate-700 text-[11px] font-medium">
                            <FileText className="w-3 h-3 text-slate-500" /> KTP: {ktpUrl ? 'Tersedia' : 'Belum tersedia'} • Lahan: {landPhotoUrl ? 'Tersedia' : 'Belum tersedia'}
                          </span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="inline-block px-2.5 py-0.5 rounded-full text-[11px] font-semibold border bg-amber-50 text-amber-600 border-amber-200/80">
                            {statusLabel}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => {
                              setSelectedApp(app);
                              setActionNotes('');
                              setShowVerifyModal(true);
                            }}
                            className="px-3.5 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-xs transition-colors cursor-pointer"
                          >
                            Periksa
                          </button>
                        </td>
                      </tr>
                    );})}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 3. TAB: PENUGASAN PPL                                     */}
        {/* ========================================================= */}
        {activeTab === 'penugasan' && (
          <div className="space-y-6">
            {/* Hero Banner */}
            <div className="rounded-2xl bg-slate-950 text-white p-6 sm:p-7 relative overflow-hidden shadow-xs border border-slate-800">
              <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                  <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                    <UserCheck className="w-4 h-4 text-emerald-400 stroke-[2.2]" /> MANAJEMEN PENUGASAN LAPANGAN
                  </div>
                  <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
                    Penugasan PPL
                  </h1>
                  <p className="mt-1 text-xs sm:text-sm text-slate-400 leading-relaxed">
                    Distribusikan pengajuan yang sudah lengkap kepada penyuluh berdasarkan wilayah kerja dan kapasitas aktif.
                  </p>
                </div>
              </div>
            </div>

            {/* 4 KPI Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-3.5">
              <KPICard
                title="SIAP DITUGASKAN"
                value={pendingAssignApps.length}
                subtitle="Berkas lolos verifikasi"
                icon={UserCheck}
                color="blue"
                badge="Antrean"
              />
              <KPICard
                title="PPL AKTIF"
                value={pplOfficers.length}
                subtitle="Petugas tersedia"
                icon={Users}
                color="emerald"
                badge="Kapasitas"
              />
              <KPICard
                title="BEBAN TINGGI"
                value={highWorkloadPplCount}
                subtitle="Lebih dari 8 kunjungan"
                icon={ShieldAlert}
                color="amber"
                badge="Perhatian"
              />
              <KPICard
                title="KUNJUNGAN HARI INI"
                value={assignmentsToday}
                subtitle="Penugasan hari ini"
                icon={TrendingUp}
                color="purple"
                badge="Target"
              />
            </div>

            {/* Filter Bar */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
              <div className="relative flex-1">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Cari pengajuan, petani, desa, atau PPL..."
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-hidden focus:border-emerald-500 shadow-2xs"
                />
              </div>
              <div className="flex items-center gap-2">
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Belum Ditugaskan</option>
                  <option>Semua Penugasan</option>
                  <option>Sedang Disurvei</option>
                  <option>Survei Selesai</option>
                </select>
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Semua Kecamatan</option>
                  <option>Trowulan</option>
                  <option>Mojosari</option>
                  <option>Puri</option>
                  <option>Jatirejo</option>
                  <option>Sooko</option>
                </select>
                <button
                  type="button"
                  className="p-2.5 bg-white border border-slate-200/90 hover:bg-slate-50 text-slate-600 rounded-xl shadow-2xs cursor-pointer"
                  title="Filter Lanjutan"
                >
                  <SlidersHorizontal className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Data Table: Daftar Penugasan Lapangan */}
            <div className="bg-white rounded-2xl border border-slate-200/90 shadow-xs overflow-hidden">
              <div className="p-5 sm:p-6 border-b border-slate-100 flex items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Daftar Penugasan Lapangan</h3>
                  <p className="text-xs text-slate-400 mt-0.5">Monitoring distribusi tugas verifikasi faktual lapangan bagi petugas PPL.</p>
                </div>
                <span className="bg-blue-50 text-blue-600 font-semibold text-xs px-2.5 py-1 rounded-full border border-blue-100/80 shrink-0">
                  {assignmentApps.length} ditampilkan
                </span>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50/80 text-slate-400 uppercase text-[10px] font-bold tracking-wider border-b border-slate-100">
                    <tr>
                      <th className="py-3 px-4">NO. PENGAJUAN</th>
                      <th className="py-3 px-4">PETANI / LOKASI</th>
                      <th className="py-3 px-4">KOMODITAS</th>
                      <th className="py-3 px-4">PPL</th>
                      <th className="py-3 px-4">STATUS</th>
                      <th className="py-3 px-4 text-center">AKSI</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {assignmentApps.map((app) => {
                      const isPending = app.status === 'BERKAS_TERVERIFIKASI';
                      const assignedPpl = pplOfficers.find((officer) => officer.id === app.assigned_ppl_id);
                      const statusLabel = {
                        BERKAS_TERVERIFIKASI: 'Siap Ditugaskan',
                        DITUGASKAN_KE_PPL: 'Ditugaskan ke PPL',
                        SURVEI_LAPANGAN: 'Sedang Disurvei',
                        MENUNGGU_PERSETUJUAN_AKHIR: 'Survei Selesai',
                      }[app.status] || app.status;
                      const statusClass = isPending
                        ? 'bg-blue-50 text-blue-600 border-blue-200/80'
                        : app.status === 'MENUNGGU_PERSETUJUAN_AKHIR'
                          ? 'bg-emerald-50 text-emerald-600 border-emerald-200/80'
                          : 'bg-amber-50 text-amber-600 border-amber-200/80';
                      return (
                      <tr key={app.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3.5 px-4 font-mono">
                          <span className="font-bold text-slate-900 block">#{app.id}</span>
                          <span className="text-[10px] text-slate-400 font-sans">{new Date(app.assigned_at || app.tanggal_pengajuan).toLocaleString('id-ID')}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <strong className="block text-slate-900 font-bold">{app.farmer?.nama || 'Belum tersedia'}</strong>
                          <span className="text-[11px] text-slate-400 flex items-center gap-1 mt-0.5">
                            <MapPin className="w-3 h-3 text-slate-400" /> {app.land?.lokasi_deskripsi || app.alamat_lahan || app.land?.alamat_lahan || 'Lokasi belum tersedia'}
                          </span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="font-semibold text-slate-800 block">{app.fertilizer?.nama_pupuk || 'Pupuk belum tersedia'} ({app.jumlah_diajukan} {app.fertilizer?.satuan || 'kg'})</span>
                          <span className="text-[11px] text-slate-400">{app.land?.commodity?.nama_komoditas || 'Komoditas belum tersedia'} • {app.land?.luas_m2 ? `${(Number(app.land.luas_m2) / 10000).toLocaleString('id-ID')} Ha` : 'Luas belum tersedia'}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className={`font-semibold block ${!assignedPpl ? 'text-amber-600' : 'text-slate-800'}`}>
                            {assignedPpl?.username || 'Belum Ditugaskan'}
                          </span>
                          <span className="text-[11px] text-slate-400">{assignedPpl?.wilayah || (isPending ? 'Menunggu Alokasi PPL' : 'Petugas tidak tersedia')}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className={`inline-block px-2.5 py-0.5 rounded-full text-[11px] font-semibold border ${statusClass}`}>
                            {statusLabel}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => {
                              if (isPending) {
                                setSelectedApp(app);
                                setActionNotes('');
                                setShowAssignModal(true);
                              } else {
                                toast.success(`Pengajuan #${app.id}: ${statusLabel} — ${assignedPpl?.username || 'PPL belum tersedia'}`);
                              }
                            }}
                            className={`px-3.5 py-1.5 rounded-lg font-bold text-xs shadow-xs transition-colors cursor-pointer ${
                              isPending
                                ? 'bg-blue-600 hover:bg-blue-700 text-white'
                                : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                            }`}
                          >
                            {isPending ? 'Tugaskan' : 'Detail'}
                          </button>
                        </td>
                      </tr>
                    );})}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 4. TAB: PERSETUJUAN AKHIR                                 */}
        {/* ========================================================= */}
        {activeTab === 'approval' && (
          <div className="space-y-6">
            {/* Hero Banner */}
            <div className="rounded-2xl bg-slate-950 text-white p-6 sm:p-7 relative overflow-hidden shadow-xs border border-slate-800">
              <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                  <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                    <Award className="w-4 h-4 text-emerald-400 stroke-[2.2]" /> KEPUTUSAN ALOKASI SUBSIDI
                  </div>
                  <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
                    Persetujuan Akhir
                  </h1>
                  <p className="mt-1 text-xs sm:text-sm text-slate-400  leading-relaxed">
                    Tetapkan keputusan akhir berdasarkan hasil verifikasi lapangan, saldo e-RDKK, dan rekomendasi PPL.
                  </p>
                </div>
              </div>
            </div>

            {/* 4 KPI Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-3.5">
              <KPICard
                title="MENUNGGU KEPUTUSAN"
                value={pendingFinalApps.length}
                subtitle="Hasil survei menunggu keputusan"
                icon={Award}
                color="purple"
                badge="Prioritas"
              />
              <KPICard
                title="DISETUJUI MT-1"
                value={approvedApps.length}
                subtitle="Pengajuan disetujui"
                icon={TrendingUp}
                color="emerald"
                badge="Realisasi"
              />
              <KPICard
                title="DISETUJUI BERSYARAT"
                value="—"
                subtitle="Kategori tidak tersedia"
                icon={ShieldAlert}
                color="amber"
                badge="Catatan"
              />
              <KPICard
                title="DITOLAK"
                value={rejectedApps.length}
                subtitle="Pengajuan ditolak"
                icon={ShieldAlert}
                color="rose"
                badge="Tidak Lolos"
              />
            </div>

            {/* Filter Bar */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
              <div className="relative flex-1">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Cari tiket eskalasi, petani, Poktan, atau PPL..."
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-hidden focus:border-emerald-500 shadow-2xs"
                />
              </div>
              <div className="flex items-center gap-2">
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Menunggu Keputusan</option>
                  <option>Semua Status</option>
                  <option>Disetujui</option>
                  <option>Ditolak</option>
                </select>
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Semua Urgensi</option>
                  <option>Urgensi Tinggi</option>
                  <option>Urgensi Normal</option>
                </select>
                <button
                  type="button"
                  className="p-2.5 bg-white border border-slate-200/90 hover:bg-slate-50 text-slate-600 rounded-xl shadow-2xs cursor-pointer"
                  title="Filter Lanjutan"
                >
                  <SlidersHorizontal className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Data Table: Antrean Persetujuan Akhir */}
            <div className="bg-white rounded-2xl border border-slate-200/90 shadow-xs overflow-hidden">
              <div className="p-5 sm:p-6 border-b border-slate-100 flex items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Antrean Persetujuan Akhir</h3>
                  <p className="text-xs text-slate-400 mt-0.5">Verifikasi final dokumen hasil survei fisik PPL sebelum menerbitkan alokasi pupuk bersubsidi.</p>
                </div>
                <span className="bg-blue-50 text-blue-600 font-semibold text-xs px-2.5 py-1 rounded-full border border-blue-100/80 shrink-0">
                  {pendingFinalApps.length} ditampilkan
                </span>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50/80 text-slate-400 uppercase text-[10px] font-bold tracking-wider border-b border-slate-100">
                    <tr>
                      <th className="py-3 px-4">TIKET ESKALASI</th>
                      <th className="py-3 px-4">PETANI / POKTAN</th>
                      <th className="py-3 px-4">TEMUAN SURVEI</th>
                      <th className="py-3 px-4">REKOMENDASI PPL</th>
                      <th className="py-3 px-4">STATUS</th>
                      <th className="py-3 px-4 text-center">AKSI</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {pendingFinalApps.map((app) => (
                      <tr key={app.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3.5 px-4 font-mono">
                          <span className="font-bold text-slate-900 block">#{app.id}</span>
                          <span className="text-[10px] text-slate-400 font-sans">{new Date(app.survey?.tanggal_survei || app.updated_at || app.tanggal_pengajuan).toLocaleString('id-ID')}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <strong className="block text-slate-900 font-bold">{app.farmer?.nama || 'Belum tersedia'}</strong>
                          <span className="text-[11px] text-slate-400">{app.farmer?.farmer_group?.nama_kelompok || 'Poktan belum tersedia'}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="font-medium text-slate-800 block">{app.survey?.keterangan_fisik_lahan || app.survey?.kondisi_fisik_lahan || 'Temuan survei belum tersedia'}</span>
                          <span className="text-[11px] text-slate-400">Luas aktual: {app.survey?.luas_lahan_aktual_m2 ? `${(Number(app.survey.luas_lahan_aktual_m2) / 10000).toLocaleString('id-ID')} Ha` : 'Belum tersedia'}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className={`inline-block px-2.5 py-1 rounded-md text-[11px] font-bold border ${app.survey?.rekomendasi === 'SETUJU' ? 'bg-emerald-50 text-emerald-700 border-emerald-200/80' : 'bg-amber-50 text-amber-700 border-amber-200/80'}`}>
                            {app.survey?.rekomendasi || 'Belum tersedia'}
                          </span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="inline-block px-2.5 py-0.5 rounded-full text-[11px] font-semibold border bg-purple-50 text-purple-600 border-purple-200/80">
                            Menunggu Keputusan
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => navigateToAdminTab('approval', app.id)}
                            className="px-3.5 py-1.5 rounded-lg font-bold text-xs shadow-xs transition-colors cursor-pointer bg-purple-600 hover:bg-purple-700 text-white"
                          >
                            Putuskan
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 5. TAB: DATA PETANI                                       */}
        {/* ========================================================= */}
        {activeTab === 'petani' && (
          <div className="space-y-6">
            {/* Hero Banner */}
            <div className="rounded-2xl bg-slate-950 text-white p-6 sm:p-7 relative overflow-hidden shadow-xs border border-slate-800">
              <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                  <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                    <Users className="w-4 h-4 text-emerald-400 stroke-[2.2]" /> DATABASE MASTER PETANI
                  </div>
                  <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
                    Data Petani
                  </h1>
                  <p className="mt-1 text-xs sm:text-sm text-slate-400 leading-relaxed">
                    Kelola basis data petani penerima subsidi yang tersinkron dengan SIMLUHTAN dan keanggotaan kelompok tani.
                  </p>
                </div>
              </div>
            </div>

            {/* 4 KPI Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-3.5">
              <KPICard
                title="TOTAL PETANI"
                value={uniqueFarmers.length.toLocaleString('id-ID')}
                subtitle="Terdaftar di sistem"
                icon={Users}
                color="blue"
                badge="SIMLUHTAN"
              />
              <KPICard
                title="DATA AKTIF"
                value="—"
                subtitle="Status akun tidak tersedia"
                icon={PackageCheck}
                color="emerald"
                badge="Valid"
              />
              <KPICard
                title="PERLU SINKRON"
                value={farmersWithoutGroup.toLocaleString('id-ID')}
                subtitle="Belum terhubung ke Poktan"
                icon={ShieldAlert}
                color="amber"
                badge="Anomali"
              />
              <KPICard
                title="NONAKTIF"
                value="—"
                subtitle="Status akun tidak tersedia"
                icon={ShieldAlert}
                color="rose"
                badge="Arsip"
              />
            </div>

            {/* Filter Bar */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
              <div className="relative flex-1">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Cari nama petani, NIK, atau kelompok tani..."
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-hidden focus:border-emerald-500 shadow-2xs"
                />
              </div>
              <div className="flex items-center gap-2">
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Semua Wilayah</option>
                  <option>Kec. Trowulan</option>
                  <option>Kec. Mojosari</option>
                  <option>Kec. Puri</option>
                  <option>Kec. Dlanggu</option>
                  <option>Kec. Sooko</option>
                </select>
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Status Aktif</option>
                  <option>Semua Status</option>
                  <option>Perlu Sinkron</option>
                  <option>Nonaktif</option>
                </select>
                <button
                  type="button"
                  className="p-2.5 bg-white border border-slate-200/90 hover:bg-slate-50 text-slate-600 rounded-xl shadow-2xs cursor-pointer"
                  title="Filter Lanjutan"
                >
                  <SlidersHorizontal className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Data Table: Daftar Petani Kabupaten Mojokerto */}
            <div className="bg-white rounded-2xl border border-slate-200/90 shadow-xs overflow-hidden">
              <div className="p-5 sm:p-6 border-b border-slate-100 flex items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Daftar Petani Kabupaten Mojokerto</h3>
                  <p className="text-xs text-slate-400 mt-0.5">Data induk petani penerima alokasi pupuk bersubsidi yang terhubung SIMLUHTAN.</p>
                </div>
                <span className="bg-blue-50 text-blue-600 font-semibold text-xs px-2.5 py-1 rounded-full border border-blue-100/80 shrink-0">
                  {uniqueFarmers.length} ditampilkan
                </span>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50/80 text-slate-400 uppercase text-[10px] font-bold tracking-wider border-b border-slate-100">
                    <tr>
                      <th className="py-3 px-4">NAMA / NIK</th>
                      <th className="py-3 px-4">KELOMPOK TANI</th>
                      <th className="py-3 px-4">ALAMAT</th>
                      <th className="py-3 px-4">LUAS AKTIF</th>
                      <th className="py-3 px-4">STATUS</th>
                      <th className="py-3 px-4 text-center">AKSI</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {uniqueFarmers.map((farmer) => {
                      const farmerLandArea = uniqueLands
                        .filter((land) => land.farmer_id === farmer.id)
                        .reduce((total, land) => total + Number(land.luas_m2 || 0), 0);
                      const farmerApplications = applications.filter((app) => app.farmer_id === farmer.id);
                      const latestApplication = farmerApplications[0];
                      const hasGroup = Boolean(farmer.farmer_group_id);
                      return (
                      <tr key={farmer.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3.5 px-4">
                          <strong className="block text-slate-900 font-bold">{farmer.nama}</strong>
                          <span className="font-mono text-[11px] text-slate-400">NIK: {farmer.nik}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="font-semibold text-slate-800 block">{farmer.farmer_group?.nama_kelompok || 'Belum terdaftar'}</span>
                          <span className="text-[11px] text-slate-400">{farmer.farmer_group?.wilayah || 'Wilayah belum tersedia'}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="text-slate-800 font-medium block">{farmer.alamat || 'Alamat belum tersedia'}</span>
                          <span className="text-[11px] text-slate-400">
                            Pengajuan: {farmerApplications.length} • Wilayah Poktan: {farmer.farmer_group?.wilayah || 'Belum tersedia'}
                          </span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="font-bold text-slate-900">{(farmerLandArea / 10000).toLocaleString('id-ID')} Ha</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className={`inline-block px-2.5 py-0.5 rounded-full text-[11px] font-semibold border ${latestApplication ? 'bg-blue-50 text-blue-600 border-blue-200/80' : hasGroup ? 'bg-emerald-50 text-emerald-600 border-emerald-200/80' : 'bg-amber-50 text-amber-600 border-amber-200/80'}`}>
                            {latestApplication?.status || (hasGroup ? 'Terdaftar' : 'Poktan Belum Tersedia')}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => setSelectedFarmerDetail(farmer)}
                            className="px-3.5 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs shadow-xs transition-colors cursor-pointer"
                          >
                            Detail
                          </button>
                        </td>
                      </tr>
                    );})}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 6. TAB: DATA LAHAN                                        */}
        {/* ========================================================= */}
        {activeTab === 'lahan' && (
          <div className="space-y-6">
            {/* Hero Banner */}
            <div className="rounded-2xl bg-slate-950 text-white p-6 sm:p-7 relative overflow-hidden shadow-xs border border-slate-800">
              <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                  <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                    <LandPlot className="w-4 h-4 text-emerald-400 stroke-[2.2]" /> GEODATA & BIDANG SPASIAL
                  </div>
                  <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
                    Data Lahan
                  </h1>
                  <p className="mt-1 text-xs sm:text-sm text-slate-400 leading-relaxed">
                    Pantau bidang lahan, status kepemilikan, luas tanam, dan hasil validasi spasial pengajuan pupuk bersubsidi.
                  </p>
                </div>
              </div>
            </div>

            {/* 4 KPI Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-3.5">
              <KPICard
                title="TOTAL BIDANG"
                value={uniqueLands.length.toLocaleString('id-ID')}
                subtitle={`${(totalLandAreaM2 / 10000).toLocaleString('id-ID')} Ha`}
                icon={LandPlot}
                color="blue"
                badge="Total Area"
              />
              <KPICard
                title="TERVALIDASI"
                value="—"
                subtitle="Status validasi belum tersedia"
                icon={PackageCheck}
                color="emerald"
                badge="Poligon Sah"
              />
              <KPICard
                title="ANOMALI SPASIAL"
                value="—"
                subtitle="Data anomali belum tersedia"
                icon={ShieldAlert}
                color="rose"
                badge="Overlap"
              />
              <KPICard
                title="PERLU SURVEI"
                value={landsAwaitingSurvey.toLocaleString('id-ID')}
                subtitle="Dalam antrean PPL"
                icon={TrendingUp}
                color="amber"
                badge="Verifikasi Lapangan"
              />
            </div>

            {/* Filter Bar */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
              <div className="relative flex-1">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Cari ID lahan, pemilik, desa, atau nomor SPPT..."
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-hidden focus:border-emerald-500 shadow-2xs"
                />
              </div>
              <div className="flex items-center gap-2">
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Semua Kecamatan</option>
                  <option>Trowulan</option>
                  <option>Mojosari</option>
                  <option>Puri</option>
                  <option>Sooko</option>
                  <option>Dlanggu</option>
                </select>
                <select className="px-3.5 py-2.5 bg-white border border-slate-200/90 rounded-xl text-xs font-semibold text-slate-700 focus:outline-hidden focus:border-emerald-500 shadow-2xs cursor-pointer">
                  <option>Semua Validasi</option>
                  <option>Tervalidasi SIG</option>
                  <option>Perlu Survei</option>
                  <option>Anomali Spasial</option>
                </select>
                <button
                  type="button"
                  className="p-2.5 bg-white border border-slate-200/90 hover:bg-slate-50 text-slate-600 rounded-xl shadow-2xs cursor-pointer"
                  title="Filter Lanjutan"
                >
                  <SlidersHorizontal className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Data Table: Register Bidang Lahan */}
            <div className="bg-white rounded-2xl border border-slate-200/90 shadow-xs overflow-hidden">
              <div className="p-5 sm:p-6 border-b border-slate-100 flex items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Register Bidang Lahan</h3>
                  <p className="text-xs text-slate-400 mt-0.5">Peta dan atribut bidang lahan garapan petani penerima alokasi pupuk bersubsidi.</p>
                </div>
                <span className="bg-blue-50 text-blue-600 font-semibold text-xs px-2.5 py-1 rounded-full border border-blue-100/80 shrink-0">
                  {uniqueLands.length} ditampilkan
                </span>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50/80 text-slate-400 uppercase text-[10px] font-bold tracking-wider border-b border-slate-100">
                    <tr>
                      <th className="py-3 px-4">ID LAHAN</th>
                      <th className="py-3 px-4">PEMILIK</th>
                      <th className="py-3 px-4">LOKASI BIDANG</th>
                      <th className="py-3 px-4">KOMODITAS / LUAS</th>
                      <th className="py-3 px-4">STATUS</th>
                      <th className="py-3 px-4 text-center">AKSI</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {uniqueLands.map((land) => {
                      const owner = uniqueFarmers.find((farmer) => farmer.id === land.farmer_id);
                      const hasPhoto = Boolean(land.foto_lahan_url);
                      const ownershipLabel = land.status_kepemilikan || 'Belum tersedia';
                      return (
                      <tr key={land.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3.5 px-4 font-mono">
                          <span className="font-bold text-slate-900 block">#{land.id}</span>
                          <span className="text-[10px] text-slate-400 font-sans">Foto bukti: {hasPhoto ? 'Tersedia' : 'Belum tersedia'}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <strong className="block text-slate-900 font-bold">{owner?.nama || 'Petani belum tersedia'}</strong>
                          <span className="text-[11px] text-slate-400">NIK: {owner?.nik || 'Belum tersedia'}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="text-slate-800 font-medium block">{land.lokasi_deskripsi || land.alamat_lahan || 'Lokasi belum tersedia'}</span>
                          <span className="text-[11px] text-slate-400 flex items-center gap-1">
                            <MapPin className="w-3 h-3 text-slate-400" /> {land.alamat_lahan || 'Alamat belum tersedia'}
                          </span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="font-semibold text-slate-800 block">{land.commodity?.nama_komoditas || 'Komoditas belum tersedia'}</span>
                          <span className="text-[11px] text-slate-400">{Number(land.luas_m2 || 0).toLocaleString('id-ID')} m² ({(Number(land.luas_m2 || 0) / 10000).toLocaleString('id-ID')} Ha)</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className={`inline-block px-2.5 py-0.5 rounded-full text-[11px] font-semibold border ${land.status_kepemilikan === 'MILIK' ? 'bg-emerald-50 text-emerald-600 border-emerald-200/80' : 'bg-amber-50 text-amber-600 border-amber-200/80'}`}>
                            {ownershipLabel}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => setSelectedLandDetail(land)}
                            className="px-3.5 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 font-bold text-xs shadow-xs transition-colors cursor-pointer border border-emerald-200/80"
                          >
                            Detail
                          </button>
                        </td>
                      </tr>
                    );})}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 7. TAB: MONITORING                                        */}
        {/* ========================================================= */}
        {activeTab === 'monitoring' && (
          <div className="space-y-6">
            <div className="rounded-2xl bg-slate-950 text-white p-6 sm:p-7 relative overflow-hidden shadow-xs border border-slate-800">
              <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                  <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                    <BarChart3 className="w-4 h-4 text-emerald-400 stroke-[2.2]" /> MONITORING REALISASI
                  </div>
                  <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
                    Monitoring Distribusi & Kuota
                  </h1>
                  <p className="mt-1 text-xs sm:text-sm text-slate-400 max-w-2xl leading-relaxed">
                    Pantau grafik perkembangan alokasi pupuk bersubsidi, status pengajuan, dan realisasi penebusan petani.
                  </p>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 lg:grid-cols-5 gap-3 sm:gap-3.5">
              <div className="bg-white rounded-2xl border border-slate-200/90 p-4 shadow-xs">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">TOTAL PETANI</span>
                <strong className="block text-xl font-black text-slate-900 mt-1">{stats?.total_petani || uniqueFarmers.length}</strong>
              </div>
              <div className="bg-white rounded-2xl border border-slate-200/90 p-4 shadow-xs">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">TOTAL LAHAN</span>
                <strong className="block text-xl font-black text-slate-900 mt-1">{uniqueLands.length}</strong>
              </div>
              <div className="bg-white rounded-2xl border border-slate-200/90 p-4 shadow-xs">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">TOTAL PENGAJUAN</span>
                <strong className="block text-xl font-black text-slate-900 mt-1">{applications.length}</strong>
              </div>
              <div className="bg-white rounded-2xl border border-slate-200/90 p-4 shadow-xs">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">PUPUK DISETUJUI</span>
                <strong className="block text-xl font-black text-emerald-600 mt-1">{totalApprovedKg} kg</strong>
              </div>
              <div className="bg-white rounded-2xl border border-slate-200/90 p-4 shadow-xs">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">PUPUK TERPANTAU</span>
                <strong className="block text-xl font-black text-blue-600 mt-1">100% Sah</strong>
              </div>
            </div>

            <div className="bg-white rounded-2xl border border-slate-200/90 p-5 sm:p-6 shadow-xs">
              <h3 className="text-base font-bold text-slate-900 mb-4">Status Pengajuan Keseluruhan</h3>
              <div className="space-y-3.5">
                {[
                  ['Menunggu verifikasi berkas', pendingVerifyApps.length, 'bg-amber-500'],
                  ['Menunggu penugasan PPL', pendingAssignApps.length, 'bg-blue-500'],
                  ['Menunggu persetujuan akhir', pendingFinalApps.length, 'bg-purple-500'],
                  ['Alokasi disetujui dinas', approvedApps.length, 'bg-emerald-500'],
                ].map(([label, value, color]) => (
                  <div key={label} className="flex items-center gap-3 text-xs">
                    <span className="w-48 font-medium text-slate-600">{label}</span>
                    <div className="h-2.5 flex-1 rounded-full bg-slate-100 overflow-hidden">
                      <div className={`h-full ${color} rounded-full`} style={{ width: `${applications.length ? Math.max(8, (value / applications.length) * 100) : 8}%` }} />
                    </div>
                    <strong className="w-10 text-right font-bold text-slate-900">{value}</strong>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 8. TAB: LAPORAN                                           */}
        {/* ========================================================= */}
        {activeTab === 'laporan' && (
          <div className="bg-white rounded-2xl border border-slate-200/90 p-6 shadow-xs space-y-5">
            <div className="border-b border-slate-100 pb-4">
              <h3 className="text-base font-bold text-slate-900">Laporan Administrasi Dinas Pertanian</h3>
              <p className="text-xs text-slate-400 mt-0.5">Ekspor berkas laporan resmi untuk pelaporan instansi dan dinas ketahanan pangan.</p>
            </div>
            <div className="flex flex-wrap items-center gap-2.5">
              <input type="date" className="px-3 py-2 rounded-xl border border-slate-200 text-xs bg-white text-slate-700 font-medium" />
              <span className="text-xs text-slate-400 font-semibold">sampai</span>
              <input type="date" className="px-3 py-2 rounded-xl border border-slate-200 text-xs bg-white text-slate-700 font-medium" />
              <select className="px-3.5 py-2 rounded-xl border border-slate-200 text-xs bg-white text-slate-700 font-semibold">
                <option>Semua Kecamatan</option>
                <option>Trowulan</option>
                <option>Mojosari</option>
                <option>Puri</option>
              </select>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
              {['Data Petani Terdaftar', 'Register Bidang Lahan', 'Pengajuan & Verifikasi Berkas', 'Hasil Survei Lapangan PPL', 'Surat Keputusan Persetujuan', 'Distribusi Pupuk Bersubsidi'].map((report) => (
                <div key={report} className="border border-slate-200/90 rounded-2xl p-4.5 bg-slate-50/50 hover:bg-white transition-all shadow-2xs">
                  <ClipboardList className="w-5 h-5 text-emerald-600 mb-2.5" />
                  <h4 className="text-xs font-bold text-slate-900">{report}</h4>
                  <div className="flex gap-2.5 mt-3.5 pt-3 border-t border-slate-100">
                    <button onClick={() => toast.success(`Laporan ${report} diekspor ke PDF`)} className="text-xs font-bold text-rose-600 hover:text-rose-700 cursor-pointer">Export PDF</button>
                    <button onClick={() => toast.success(`Laporan ${report} diekspor ke Excel`)} className="text-xs font-bold text-emerald-600 hover:text-emerald-700 cursor-pointer">Export Excel</button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 9. TAB: MANAJEMEN PENGGUNA                                */}
        {/* ========================================================= */}
        {activeTab === 'pengguna' && (
          <div className="bg-white rounded-2xl border border-slate-200/90 p-6 shadow-xs space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div>
                <h3 className="text-base font-bold text-slate-900">Manajemen Pengguna Sistem</h3>
                <p className="text-xs text-slate-400 mt-0.5">Kelola hak akses untuk Petani, Petugas PPL Lapangan, dan Staf Dinas.</p>
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-400 uppercase text-[10px] font-bold">
                  <tr>
                    <th className="py-3 px-4">Nama Lengkap</th>
                    <th className="py-3 px-4">Username</th>
                    <th className="py-3 px-4">Peran / Role</th>
                    <th className="py-3 px-4">Status</th>
                    <th className="py-3 px-4 text-center">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {[...uniqueFarmers.map((f) => ({ name: f.nama, username: f.user?.username || f.nik, role: 'PETANI' })), ...pplOfficers.map((p) => ({ name: p.username, username: p.username, role: 'PPL LAPANGAN' }))].map((person, idx) => (
                    <tr key={person.role + idx} className="hover:bg-slate-50/60">
                      <td className="py-3 px-4 font-bold text-slate-900">{person.name}</td>
                      <td className="py-3 px-4 font-mono text-slate-500">{person.username}</td>
                      <td className="py-3 px-4"><span className="px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-700 text-[10px] font-bold">{person.role}</span></td>
                      <td className="py-3 px-4"><span className="text-emerald-600 font-bold">Aktif</span></td>
                      <td className="py-3 px-4 text-center"><button onClick={() => toast.success(`Detail akun ${person.name}`)} className="text-emerald-700 font-bold hover:underline cursor-pointer">Detail</button></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* 10. TAB: AUDIT LOG                                        */}
        {/* ========================================================= */}
        {activeTab === 'audit' && (
          <div className="bg-white rounded-2xl border border-slate-200/90 p-6 shadow-xs space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div>
                <h3 className="text-base font-bold text-slate-900">Catatan Jejak Keamanan & Akses Sistem (Audit Logs)</h3>
                <p className="text-xs text-slate-400 mt-0.5">Mencatat riwayat aktivitas verifikasi, disposisi PPL, dan keputusan final alokasi.</p>
              </div>
              <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-slate-100 text-slate-600">
                {auditLogs.length || 50} Aktivitas
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-400 uppercase text-[10px] font-bold">
                  <tr>
                    <th className="py-3 px-4">Waktu</th>
                    <th className="py-3 px-4">Aksi</th>
                    <th className="py-3 px-4">Resource</th>
                    <th className="py-3 px-4">Keterangan</th>
                    <th className="py-3 px-4">IP Address</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {auditLogs.map((log) => (
                    <tr key={log.id} className="hover:bg-slate-50/50">
                      <td className="py-3 px-4 font-mono text-[11px] text-slate-400">{new Date(log.created_at).toLocaleString('id-ID')}</td>
                      <td className="py-3 px-4 font-bold text-slate-900"><span className="px-2 py-0.5 rounded-md bg-slate-100 font-mono text-[10px]">{log.action}</span></td>
                      <td className="py-3 px-4 font-semibold text-emerald-800">{log.resource} #{log.resource_id || ''}</td>
                      <td className="py-3 px-4 text-slate-600 max-w-xs truncate">{log.details || '-'}</td>
                      <td className="py-3 px-4 font-mono text-[11px] text-slate-400">{log.ip_address || '127.0.0.1'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      {showVerifyModal && selectedApp && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-lg w-full max-h-[90vh] overflow-y-auto p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">
                Pemeriksaan Berkas Pengajuan #{selectedApp.id}
              </h3>
              <button
                onClick={() => setShowVerifyModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {(() => {
              const farmer = selectedApp.farmer;
              const land = selectedApp.land;
              const ktpUrl = selectedApp.foto_ktp_snapshot_url || farmer?.foto_ktp_url;
              const landPhotoUrl = selectedApp.foto_lahan_snapshot_url || land?.foto_lahan_url;
              const needsRevision = selectedApp.status === 'PERLU_PERBAIKAN_BERKAS';
              const documentStatus = (url) => (
                needsRevision ? 'Perlu Perbaikan' : url ? 'Lengkap' : 'Belum Ada'
              );
              const statusClass = (url) => (
                needsRevision
                  ? 'bg-amber-50 text-amber-700 border-amber-200'
                  : url
                    ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                    : 'bg-slate-100 text-slate-600 border-slate-200'
              );
              const surveyPhotos = Array.isArray(selectedApp.survey?.foto_survei_urls)
                ? selectedApp.survey.foto_survei_urls
                : [];
              const openDocument = (title, url, description) => setViewerPhoto({
                isOpen: true,
                title,
                url,
                secondaryUrl: '',
                secondaryTitle: '',
                description,
              });

              return (
                <div className="space-y-4">
                  <section className="rounded-xl border border-slate-200 p-4 space-y-2">
                    <h4 className="text-xs font-bold uppercase tracking-wide text-slate-700">Data Pemohon</h4>
                    <p className="text-xs text-slate-600">
                      Nama: <strong className="text-slate-900">{farmer?.nama || 'Belum tersedia'}</strong>
                    </p>
                    <p className="text-xs text-slate-600">
                      NIK: <strong className="text-slate-900">{farmer?.nik || 'Belum tersedia'}</strong>
                    </p>
                    <p className="text-xs text-slate-600">
                      Poktan: <strong className="text-slate-900">{farmer?.farmer_group?.nama_kelompok || 'Belum tersedia'}</strong>
                    </p>
                    {farmer?.farmer_group?.wilayah && (
                      <p className="text-xs text-slate-600">
                        Wilayah Poktan: <strong className="text-slate-900">{farmer.farmer_group.wilayah}</strong>
                      </p>
                    )}
                  </section>

                  <section className="rounded-xl border border-slate-200 p-4 space-y-2">
                    <div className="flex items-center justify-between gap-2">
                      <h4 className="text-xs font-bold uppercase tracking-wide text-slate-700">Dokumen KTP</h4>
                      <span className={`px-2 py-0.5 rounded-full border text-[10px] font-semibold ${statusClass(ktpUrl)}`}>
                        {documentStatus(ktpUrl)}
                      </span>
                    </div>
                    {ktpUrl ? (
                      <div className="flex items-center gap-3">
                        <img src={ktpUrl} alt="Preview dokumen KTP" className="w-24 h-16 rounded-lg border border-slate-200 object-cover bg-slate-50" />
                        <button
                          type="button"
                          onClick={() => openDocument(`Foto KTP: ${farmer?.nama || 'Pemohon'}`, ktpUrl, `NIK: ${farmer?.nik || '-'}`)}
                          className="text-xs font-bold text-emerald-700 hover:text-emerald-800 underline cursor-pointer"
                        >
                          Lihat KTP
                        </button>
                      </div>
                    ) : (
                      <p className="text-xs text-slate-500">Dokumen KTP belum tersedia.</p>
                    )}
                  </section>

                  <section className="rounded-xl border border-slate-200 p-4 space-y-2">
                    <div className="flex items-center justify-between gap-2">
                      <h4 className="text-xs font-bold uppercase tracking-wide text-slate-700">Data dan Bukti Lahan</h4>
                      <span className={`px-2 py-0.5 rounded-full border text-[10px] font-semibold ${statusClass(landPhotoUrl)}`}>
                        Bukti foto: {documentStatus(landPhotoUrl)}
                      </span>
                    </div>
                    <p className="text-xs text-slate-600">
                      Lokasi/Desa/Kecamatan: <strong className="text-slate-900">{land?.lokasi_deskripsi || selectedApp.alamat_lahan || 'Belum tersedia'}</strong>
                    </p>
                    {land?.alamat_lahan && (
                      <p className="text-xs text-slate-600">
                        Alamat lahan: <strong className="text-slate-900">{land.alamat_lahan}</strong>
                      </p>
                    )}
                    <p className="text-xs text-slate-600">
                      Luas: <strong className="text-slate-900">
                        {land?.luas_m2 != null
                          ? `${Number(land.luas_m2).toLocaleString('id-ID')} m²`
                          : 'Belum tersedia'}
                      </strong>
                    </p>
                    <p className="text-xs text-slate-600">
                      Status kepemilikan: <strong className="text-slate-900">{land?.status_kepemilikan || 'Belum tersedia'}</strong>
                    </p>
                    {landPhotoUrl ? (
                      <div className="flex items-center gap-3">
                        <img src={landPhotoUrl} alt="Preview bukti foto lahan" className="w-24 h-16 rounded-lg border border-slate-200 object-cover bg-slate-50" />
                        <button
                          type="button"
                          onClick={() => openDocument('Foto Bukti Lahan', landPhotoUrl, land?.lokasi_deskripsi || selectedApp.alamat_lahan || '')}
                          className="text-xs font-bold text-emerald-700 hover:text-emerald-800 underline cursor-pointer"
                        >
                          Lihat Bukti Lahan
                        </button>
                      </div>
                    ) : (
                      <p className="text-xs text-slate-500">Foto bukti lahan belum tersedia.</p>
                    )}
                  </section>

                  <section className="rounded-xl border border-slate-200 p-4 space-y-2">
                    <h4 className="text-xs font-bold uppercase tracking-wide text-slate-700">Dokumen Lain</h4>
                    <div className="flex items-center justify-between gap-2 text-xs">
                      <span className="text-slate-600">Bukti SPPT</span>
                      <span className="text-slate-500">Belum Ada — field dokumen SPPT belum tersedia</span>
                    </div>
                    {surveyPhotos.map((url, index) => (
                      <div key={`${url}-${index}`} className="flex items-center justify-between gap-2 text-xs">
                        <span className="text-slate-600">Foto Survei PPL {index + 1}</span>
                        <div className="flex items-center gap-2">
                          <span className={`px-2 py-0.5 rounded-full border text-[10px] font-semibold ${statusClass(url)}`}>
                            {documentStatus(url)}
                          </span>
                          <button
                            type="button"
                            onClick={() => openDocument(`Foto Survei PPL ${index + 1}`, url, selectedApp.survey?.catatan_ppl || '')}
                            className="font-bold text-emerald-700 hover:text-emerald-800 underline cursor-pointer"
                          >
                            Lihat Dokumen
                          </button>
                        </div>
                      </div>
                    ))}
                    {surveyPhotos.length === 0 && (
                      <p className="text-xs text-slate-500">Dokumen lain belum tersedia.</p>
                    )}
                  </section>
                </div>
              );
            })()}

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
              {pplOfficers.length === 0 ? (
                <div className="rounded-xl border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-700">
                  Belum ada petugas PPL aktif yang tersedia untuk penugasan saat ini.
                </div>
              ) : (
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
              )}
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
                disabled={pplOfficers.length === 0 || !selectedPplId}
                className="px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs cursor-pointer shadow-sm shadow-blue-200 disabled:opacity-50 disabled:cursor-not-allowed"
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
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-md w-full max-h-[90vh] overflow-y-auto p-6 space-y-4">
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

            <section className="rounded-xl border border-slate-200 p-3 space-y-1.5 text-xs">
              <h4 className="font-bold uppercase tracking-wide text-slate-700">Data Pengajuan dan Hasil Survei</h4>
              <p>Petani: <strong>{selectedApp.farmer?.nama || 'Belum tersedia'}</strong></p>
              <p>NIK: <strong>{selectedApp.farmer?.nik || 'Belum tersedia'}</strong></p>
              <p>Lahan: <strong>{selectedApp.land?.lokasi_deskripsi || selectedApp.alamat_lahan || selectedApp.land?.alamat_lahan || 'Belum tersedia'}</strong></p>
              <p>Luas pengajuan: <strong>{selectedApp.land?.luas_m2 != null ? `${Number(selectedApp.land.luas_m2).toLocaleString('id-ID')} m²` : 'Belum tersedia'}</strong></p>
              <p>Pupuk: <strong>{selectedApp.fertilizer?.nama_pupuk || 'Belum tersedia'}</strong></p>
              <p>Jumlah diajukan: <strong>{selectedApp.jumlah_diajukan} {selectedApp.fertilizer?.satuan || 'kg'}</strong></p>
              <p>Kondisi fisik: <strong>{selectedApp.survey?.kondisi_fisik_lahan || 'Belum tersedia'}</strong></p>
              {selectedApp.survey?.keterangan_fisik_lahan && (
                <p>Temuan fisik: <strong>{selectedApp.survey.keterangan_fisik_lahan}</strong></p>
              )}
              <p>Kondisi tanaman: <strong>{selectedApp.survey?.kondisi_tanaman || 'Belum tersedia'}</strong></p>
              {selectedApp.survey?.keterangan_tanaman && (
                <p>Keterangan tanaman: <strong>{selectedApp.survey.keterangan_tanaman}</strong></p>
              )}
              <p>Luas aktual: <strong>{selectedApp.survey?.luas_lahan_aktual_m2 != null ? `${Number(selectedApp.survey.luas_lahan_aktual_m2).toLocaleString('id-ID')} m²` : 'Belum tersedia'}</strong></p>
              <p>Catatan PPL: <strong>{selectedApp.survey?.catatan_ppl || 'Belum tersedia'}</strong></p>
              <p>Rekomendasi PPL: <strong>{selectedApp.survey?.rekomendasi || 'Belum tersedia'}</strong></p>
              {selectedApp.land?.foto_lahan_url || selectedApp.foto_lahan_snapshot_url ? (
                <button
                  type="button"
                  onClick={() => setViewerPhoto({
                    isOpen: true,
                    title: `Foto Lahan Pengajuan #${selectedApp.id}`,
                    url: selectedApp.foto_lahan_snapshot_url || selectedApp.land?.foto_lahan_url,
                    secondaryUrl: '',
                    secondaryTitle: '',
                    description: selectedApp.land?.lokasi_deskripsi || selectedApp.alamat_lahan || '',
                  })}
                  className="text-emerald-700 font-bold underline cursor-pointer"
                >
                  Lihat Foto Lahan
                </button>
              ) : (
                <p>Foto lahan: <strong>Belum tersedia</strong></p>
              )}
              {Array.isArray(selectedApp.survey?.foto_survei_urls) && selectedApp.survey.foto_survei_urls[0] && (
                <button
                  type="button"
                  onClick={() => setViewerPhoto({
                    isOpen: true,
                    title: `Foto Survei Pengajuan #${selectedApp.id}`,
                    url: selectedApp.survey.foto_survei_urls[0],
                    secondaryUrl: '',
                    secondaryTitle: '',
                    description: selectedApp.survey.catatan_ppl || '',
                  })}
                  className="ml-3 text-emerald-700 font-bold underline cursor-pointer"
                >
                  Lihat Foto Survei
                </button>
              )}
            </section>

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
                Setujui Alokasi Pupuk
              </button>
            </div>
          </div>
        </div>
      )}

      {selectedFarmerDetail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-lg w-full max-h-[90vh] overflow-y-auto p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">Detail Petani #{selectedFarmerDetail.id}</h3>
              <button
                type="button"
                onClick={() => setSelectedFarmerDetail(null)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="rounded-xl border border-slate-200 p-4 space-y-2 text-xs">
              <p>Nama: <strong>{selectedFarmerDetail.nama || 'Belum tersedia'}</strong></p>
              <p>NIK: <strong>{selectedFarmerDetail.nik || 'Belum tersedia'}</strong></p>
              <p>Poktan: <strong>{selectedFarmerDetail.farmer_group?.nama_kelompok || 'Belum tersedia'}</strong></p>
              <p>Wilayah Poktan: <strong>{selectedFarmerDetail.farmer_group?.wilayah || 'Belum tersedia'}</strong></p>
              <p>Desa: <strong>Belum tersedia pada data API</strong></p>
              <p>Kecamatan: <strong>Belum tersedia pada data API</strong></p>
              <p>Alamat: <strong>{selectedFarmerDetail.alamat || 'Belum tersedia'}</strong></p>
              <p>Jumlah pengajuan: <strong>{applications.filter((app) => app.farmer_id === selectedFarmerDetail.id).length}</strong></p>
              <p>Status pengajuan terbaru: <strong>{applications.find((app) => app.farmer_id === selectedFarmerDetail.id)?.status || 'Belum ada pengajuan'}</strong></p>
              {selectedFarmerDetail.foto_ktp_url ? (
                <button
                  type="button"
                  onClick={() => setViewerPhoto({
                    isOpen: true,
                    title: `KTP: ${selectedFarmerDetail.nama || 'Petani'}`,
                    url: selectedFarmerDetail.foto_ktp_url,
                    secondaryUrl: '',
                    secondaryTitle: '',
                    description: `NIK: ${selectedFarmerDetail.nik || 'Belum tersedia'}`,
                  })}
                  className="text-emerald-700 font-bold underline cursor-pointer"
                >
                  Lihat KTP
                </button>
              ) : (
                <p>Foto KTP: <strong>Belum tersedia</strong></p>
              )}
            </div>
            <div className="space-y-2">
              <h4 className="text-xs font-bold uppercase tracking-wide text-slate-700">Pengajuan Petani</h4>
              {applications.filter((app) => app.farmer_id === selectedFarmerDetail.id).map((app) => (
                <div key={app.id} className="rounded-xl border border-slate-200 p-3 text-xs">
                  <p>Pengajuan #{app.id} · {app.status}</p>
                  <p>{app.fertilizer?.nama_pupuk || 'Pupuk belum tersedia'} · {app.jumlah_diajukan} {app.fertilizer?.satuan || 'kg'}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {selectedLandDetail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-lg w-full max-h-[90vh] overflow-y-auto p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">Detail Lahan #{selectedLandDetail.id}</h3>
              <button
                type="button"
                onClick={() => setSelectedLandDetail(null)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            {selectedLandDetail.foto_lahan_url ? (
              <img
                src={selectedLandDetail.foto_lahan_url}
                alt={`Foto lahan ${selectedLandDetail.lokasi_deskripsi || selectedLandDetail.id}`}
                className="w-full max-h-56 rounded-xl border border-slate-200 object-cover"
              />
            ) : (
              <p className="text-xs text-slate-500">Foto lahan belum tersedia.</p>
            )}
            <div className="rounded-xl border border-slate-200 p-4 space-y-2 text-xs">
              <p>Petani: <strong>{farmersList.find((farmer) => farmer.id === selectedLandDetail.farmer_id)?.nama || 'Belum tersedia'}</strong></p>
              <p>NIK: <strong>{farmersList.find((farmer) => farmer.id === selectedLandDetail.farmer_id)?.nik || 'Belum tersedia'}</strong></p>
              <p>Lokasi: <strong>{selectedLandDetail.lokasi_deskripsi || 'Belum tersedia'}</strong></p>
              <p>Alamat: <strong>{selectedLandDetail.alamat_lahan || 'Belum tersedia'}</strong></p>
              <p>Luas: <strong>{selectedLandDetail.luas_m2 != null ? `${Number(selectedLandDetail.luas_m2).toLocaleString('id-ID')} m²` : 'Belum tersedia'}</strong></p>
              <p>Koordinat: <strong>{selectedLandDetail.latitude != null && selectedLandDetail.longitude != null
                ? `${formatCoord(selectedLandDetail.latitude)}, ${formatCoord(selectedLandDetail.longitude)}`
                : 'Belum tersedia'}</strong></p>
              <p>Status kepemilikan: <strong>{selectedLandDetail.status_kepemilikan || 'Belum tersedia'}</strong></p>
              <p>Status verifikasi: <strong>Belum tersedia dari backend</strong></p>
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
    </div>
  );
}
