import React, { useState, useEffect } from 'react';
import { 
  ShieldCheck, UserCheck, Award, FileText, Check, X,
  Eye, MapPin, Tractor,
  RefreshCw, ShieldAlert, Users, LandPlot,
  PackageCheck, BarChart3, ClipboardList, UserCog, Database,
  Search
} from 'lucide-react';
import toast from 'react-hot-toast';
import { adminApi, applicationsApi } from '../services/api';
import KPICard from '../components/KPICard';
import StatusBadge from '../components/StatusBadge';
import ProgressStepper from '../components/ProgressStepper';
import PhotoViewerModal from '../components/PhotoViewerModal';
import { formatCoord } from '../utils/format';

export default function AdminDashboard() {
  const [stats, setStats] = useState(null);
  const [applications, setApplications] = useState([]);
  const [pplOfficers, setPplOfficers] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [activeTab, setActiveTab] = useState('dashboard');
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
  const approvedApps = applications.filter((a) =>
    ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].includes(a.status)
  );
  const totalApprovedKg = approvedApps.reduce(
    (total, app) => total + Number(app.jumlah_disetujui || app.jumlah_diajukan || 0),
    0
  );
  const uniqueFarmers = Array.from(
    new Map(applications.filter((app) => app.farmer).map((app) => [app.farmer.id, app.farmer])).values()
  );
  const uniqueLands = Array.from(
    new Map(applications.filter((app) => app.land).map((app) => [app.land.id, app.land])).values()
  );
  const adminMenu = [
    { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
    { id: 'verifikasi', label: 'Verifikasi Berkas', icon: FileText, count: pendingVerifyApps.length },
    { id: 'penugasan', label: 'Penugasan PPL', icon: UserCheck, count: pendingAssignApps.length },
    { id: 'approval', label: 'Persetujuan Akhir', icon: Award, count: pendingFinalApps.length },
    { id: 'petani', label: 'Data Petani', icon: Users },
    { id: 'lahan', label: 'Data Lahan', icon: LandPlot },
    { id: 'distribusi', label: 'Data Distribusi', icon: PackageCheck },
    { id: 'monitoring', label: 'Monitoring', icon: BarChart3 },
    { id: 'laporan', label: 'Laporan', icon: ClipboardList },
    { id: 'pengguna', label: 'Manajemen Pengguna', icon: UserCog },
    { id: 'audit', label: 'Audit Log', icon: Database, count: auditLogs.length },
  ];

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
      fetchData();
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
      fetchData();
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
      await adminApi.finalApprove(selectedApp.id, {
        action,
        jumlah_disetujui: approvedKg ? parseFloat(approvedKg) : null,
        catatan: actionNotes,
      });
      setShowFinalModal(false);
      setActionNotes('');
      setApprovedKg('');
      fetchData();
      toast.success(
        action === 'APPROVE'
          ? `✅ Pengajuan #${selectedApp.id} disetujui. Alokasi pupuk siap digunakan melalui QR pada karung.`
          : `❌ Pengajuan #${selectedApp.id} ditolak.`,
        { id: toastId, duration: 5000 }
      );
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal menyimpan keputusan akhir.', { id: toastId });
    }
  };

  if (loading) {
    return (
      <div className="space-y-8 pb-16 animate-pulse">
        <div className="rounded-3xl bg-slate-200 h-32" />
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => <div key={i} className="h-28 bg-slate-200 rounded-2xl" />)}
        </div>
        <div className="h-10 bg-slate-200 rounded-xl" />
        <div className="space-y-4">
          {[...Array(3)].map((_, i) => <div key={i} className="h-48 bg-slate-200 rounded-2xl" />)}
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col lg:flex-row gap-6 pb-16">
      <aside className="hidden lg:flex lg:w-60 shrink-0 flex-col self-start sticky top-24 bg-white border border-slate-200 rounded-2xl p-3 shadow-xs">
        <div className="px-3 py-3 mb-2 border-b border-slate-100">
          <p className="text-[10px] font-bold uppercase tracking-[0.16em] text-emerald-700">Ruang Kerja</p>
          <p className="text-sm font-black text-slate-900 mt-1">Admin Dinas</p>
        </div>
        <nav className="space-y-4" aria-label="Navigasi admin">
          {[
            ['UTAMA', ['dashboard']],
            ['PENGAJUAN', ['verifikasi', 'penugasan', 'approval']],
            ['DATA', ['petani', 'lahan', 'distribusi']],
            ['MONITORING', ['monitoring', 'laporan']],
            ['SISTEM', ['pengguna', 'audit']],
          ].map(([group, itemIds]) => (
            <div key={group}>
              <p className="px-3 mb-1 text-[10px] font-bold tracking-[0.14em] text-slate-400">{group}</p>
              <div className="space-y-0.5">
                {adminMenu.filter((item) => itemIds.includes(item.id)).map((item) => {
                  const Icon = item.icon;
                  const isActive = activeTab === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => setActiveTab(item.id)}
                      className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-bold text-left transition-colors cursor-pointer ${
                        isActive ? 'bg-emerald-600 text-white shadow-sm' : 'text-slate-600 hover:bg-emerald-50 hover:text-emerald-800'
                      }`}
                    >
                      <Icon className="w-4 h-4 shrink-0" />
                      <span className="truncate">{item.label}</span>
                      {item.count !== undefined && <span className={`ml-auto text-[10px] ${isActive ? 'text-emerald-100' : 'text-slate-400'}`}>{item.count}</span>}
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
          <select id="admin-section" value={activeTab} onChange={(event) => setActiveTab(event.target.value)} className="w-full px-3 py-2.5 rounded-xl border border-slate-300 bg-white text-xs font-bold text-slate-700 outline-hidden focus:border-emerald-500">
            {adminMenu.map((item) => <option key={item.id} value={item.id}>{item.label}</option>)}
          </select>
        </div>
      {/* Top Banner */}
      <div className="rounded-2xl bg-gradient-to-r from-slate-950 via-slate-900 to-emerald-950 text-white p-6 sm:p-7 relative overflow-hidden shadow-lg border border-slate-700">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <div className="flex items-center gap-2 text-emerald-300 text-xs font-bold uppercase tracking-wider mb-2">
              <ShieldAlert className="w-4 h-4" /> Pusat Pengelolaan Subsidi
            </div>
            <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
              Dashboard Admin Dinas
            </h1>
            <p className="mt-1 text-xs sm:text-sm text-slate-300 max-w-2xl leading-relaxed">
              Kelola verifikasi pengajuan, penugasan PPL, persetujuan pupuk, dan monitoring distribusi.
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
      <div className="grid grid-cols-2 xl:grid-cols-5 gap-3">
        <KPICard
          title="Menunggu Verifikasi"
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
          title="Menunggu Persetujuan"
          value={stats?.menunggu_persetujuan_akhir || 0}
          subtitle="Hasil Survei Lapangan Siap"
          icon={Award}
          color="purple"
          badge="Keputusan"
        />
        <KPICard
          title="Total Disetujui"
          value={stats?.disetujui || 0}
          subtitle="Alokasi Pupuk Disetujui"
          icon={ShieldCheck}
          color="emerald"
          badge="Selesai"
        />
        <KPICard
          title="Total Ditolak"
          value={stats?.ditolak || 0}
          subtitle="Berkas atau survei ditolak"
          icon={ShieldAlert}
          color="rose"
          badge="Ditolak"
        />
      </div>

      {activeTab === 'dashboard' && (
        <div className="space-y-5">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
          <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200 p-5 shadow-xs">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-sm font-bold text-slate-900">Ringkasan Alur Verifikasi</h3>
                <p className="text-xs text-slate-500 mt-1">Pantau antrean yang membutuhkan tindakan Admin.</p>
              </div>
              <ClipboardList className="w-5 h-5 text-emerald-600" />
            </div>
            <div className="grid grid-cols-3 gap-3">
              {[
                ['Verifikasi Berkas', pendingVerifyApps.length, 'verifikasi', 'amber'],
                ['Penugasan PPL', pendingAssignApps.length, 'penugasan', 'blue'],
                ['Approval Akhir', pendingFinalApps.length, 'approval', 'purple'],
              ].map(([label, value, tab, color]) => (
                <button key={tab} onClick={() => setActiveTab(tab)} className="text-left rounded-xl border border-slate-200 p-3 hover:border-emerald-300 hover:bg-emerald-50/40 transition-colors cursor-pointer">
                  <span className={`text-[10px] font-bold uppercase tracking-wide text-${color}-700`}>{label}</span>
                  <strong className="block text-2xl font-black text-slate-900 mt-1">{value}</strong>
                  <span className="text-[11px] text-slate-500">Perlu ditindaklanjuti</span>
                </button>
              ))}
            </div>
          </div>
          <div className="bg-slate-900 rounded-2xl p-5 text-white shadow-xs">
            <div className="flex items-center gap-2 mb-4">
              <ShieldCheck className="w-5 h-5 text-emerald-300" />
              <h3 className="text-sm font-bold">Kinerja Sistem</h3>
            </div>
            <div className="space-y-4 text-xs">
              <div className="flex items-center justify-between"><span className="text-slate-400">Total petani</span><strong>{stats?.total_petani || uniqueFarmers.length}</strong></div>
              <div className="flex items-center justify-between"><span className="text-slate-400">Total lahan terdaftar</span><strong>{uniqueLands.length}</strong></div>
              <div className="flex items-center justify-between"><span className="text-slate-400">Total pengajuan</span><strong>{stats?.total_pengajuan || applications.length}</strong></div>
              <div className="pt-3 border-t border-slate-700 flex items-center justify-between"><span className="text-slate-400">Update terakhir</span><strong className="text-emerald-300">Hari ini</strong></div>
            </div>
          </div>
          </div>
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between gap-3">
              <div>
                <h3 className="text-sm font-bold text-slate-900">Pengajuan yang Membutuhkan Tindakan</h3>
                <p className="text-xs text-slate-500 mt-1">Prioritas kerja Admin berdasarkan tahapan proses.</p>
              </div>
              <span className="text-[11px] font-bold text-slate-400">{pendingVerifyApps.length + pendingAssignApps.length + pendingFinalApps.length} antrean</span>
            </div>
            <div className="divide-y divide-slate-100">
              {[
                ...pendingVerifyApps.map((app) => ({ app, label: 'Menunggu Verifikasi', tab: 'verifikasi', action: 'Periksa Berkas', tone: 'amber' })),
                ...pendingAssignApps.map((app) => ({ app, label: 'Siap Ditugaskan ke PPL', tab: 'penugasan', action: 'Tugaskan PPL', tone: 'blue' })),
                ...pendingFinalApps.map((app) => ({ app, label: 'Menunggu Persetujuan Akhir', tab: 'approval', action: 'Lihat Hasil Survei', tone: 'purple' })),
              ].slice(0, 6).map(({ app, label, tab, action, tone }) => (
                <div key={app.id} className="px-5 py-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <h4 className="text-sm font-bold text-slate-900">{app.farmer?.nama || 'Petani'}</h4>
                      <span className={`px-2 py-1 rounded-full text-[10px] font-bold ${tone === 'amber' ? 'bg-amber-100 text-amber-800' : tone === 'blue' ? 'bg-blue-100 text-blue-800' : 'bg-purple-100 text-purple-800'}`}>{label}</span>
                    </div>
                    <p className="text-xs text-slate-500 mt-1 truncate">{app.fertilizer?.nama_pupuk || 'Pupuk'} {app.jumlah_diajukan} kg · {app.land?.lokasi_deskripsi || app.alamat_lahan || 'Lahan terdaftar'}</p>
                  </div>
                  <button onClick={() => setActiveTab(tab)} className="shrink-0 self-start md:self-auto px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold text-emerald-700 hover:bg-emerald-50 cursor-pointer">{action}</button>
                </div>
              ))}
            </div>
            {pendingVerifyApps.length + pendingAssignApps.length + pendingFinalApps.length === 0 && <p className="py-10 text-center text-xs text-slate-400">Tidak ada pengajuan yang membutuhkan tindakan.</p>}
          </div>
        </div>
      )}

      {activeTab === 'petani' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
            <div><h3 className="text-sm font-bold text-slate-900">Data Petani</h3><p className="text-xs text-slate-500 mt-1">Profil petani yang terhubung dengan pengajuan subsidi.</p></div>
            <div className="relative"><Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" /><input placeholder="Cari nama atau NIK" className="pl-9 pr-3 py-2 rounded-xl border border-slate-300 text-xs outline-hidden focus:border-emerald-500" /></div>
          </div>
          <div className="overflow-x-auto"><table className="w-full text-left text-xs"><thead className="bg-slate-50 text-slate-500 uppercase text-[10px]"><tr><th className="p-3">No</th><th className="p-3">Nama / NIK</th><th className="p-3">Kelompok Tani</th><th className="p-3">Kontak</th><th className="p-3">Status</th><th className="p-3">Aksi</th></tr></thead><tbody className="divide-y divide-slate-100">{uniqueFarmers.map((farmer, index) => <tr key={farmer.id} className="hover:bg-slate-50"><td className="p-3 text-slate-400">{String(index + 1).padStart(2, '0')}</td><td className="p-3"><strong className="block text-slate-900">{farmer.nama}</strong><span className="font-mono text-[11px] text-slate-500">{farmer.nik}</span></td><td className="p-3 text-slate-600">{farmer.farmer_group?.nama_kelompok || '-'}</td><td className="p-3 text-slate-600">{farmer.kontak || '-'}</td><td className="p-3"><span className="px-2 py-1 rounded-full bg-emerald-100 text-emerald-800 font-bold text-[10px]">Terverifikasi</span></td><td className="p-3"><button className="text-emerald-700 font-bold hover:underline cursor-pointer">Detail</button></td></tr>)}</tbody></table></div>
          {uniqueFarmers.length === 0 && <p className="py-10 text-center text-xs text-slate-400">Belum ada data petani.</p>}
        </div>
      )}

      {activeTab === 'lahan' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs">
          <div className="mb-4"><h3 className="text-sm font-bold text-slate-900">Data Lahan</h3><p className="text-xs text-slate-500 mt-1">Lahan yang menjadi dasar pengajuan subsidi dan survei PPL.</p></div>
          <div className="overflow-x-auto"><table className="w-full text-left text-xs"><thead className="bg-slate-50 text-slate-500 uppercase text-[10px]"><tr><th className="p-3">Petani</th><th className="p-3">Blok Lahan</th><th className="p-3">Luas</th><th className="p-3">Alamat</th><th className="p-3">Koordinat</th><th className="p-3">Status</th></tr></thead><tbody className="divide-y divide-slate-100">{uniqueLands.map((land) => { const app = applications.find((item) => item.land?.id === land.id); return <tr key={land.id} className="hover:bg-slate-50"><td className="p-3 font-bold text-slate-900">{app?.farmer?.nama || '-'}</td><td className="p-3 text-slate-700">{land.lokasi_deskripsi || 'Lahan Sawah'}</td><td className="p-3 font-semibold">{land.luas_m2 || 0} m²</td><td className="p-3 text-slate-600">{app?.alamat_lahan || '-'}</td><td className="p-3 font-mono text-[11px] text-slate-500">{formatCoord(app?.latitude)}, {formatCoord(app?.longitude)}</td><td className="p-3"><span className="px-2 py-1 rounded-full bg-emerald-100 text-emerald-800 font-bold text-[10px]">Terverifikasi</span></td></tr>; })}</tbody></table></div>
          {uniqueLands.length === 0 && <p className="py-10 text-center text-xs text-slate-400">Belum ada data lahan.</p>}
        </div>
      )}

      {activeTab === 'distribusi' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs">
          <div className="mb-4"><h3 className="text-sm font-bold text-slate-900">Data Distribusi</h3><p className="text-xs text-slate-500 mt-1">Alokasi yang disetujui dan riwayat pembukaan pupuk.</p></div>
          <div className="overflow-x-auto"><table className="w-full text-left text-xs"><thead className="bg-slate-50 text-slate-500 uppercase text-[10px]"><tr><th className="p-3">Jenis Pupuk</th><th className="p-3">Disetujui</th><th className="p-3">Sudah Dibuka</th><th className="p-3">Sisa</th><th className="p-3">Petani</th><th className="p-3">Status</th></tr></thead><tbody className="divide-y divide-slate-100">{approvedApps.map((app) => { const approved = Number(app.jumlah_disetujui || app.jumlah_diajukan || 0); return <tr key={app.id} className="hover:bg-slate-50"><td className="p-3 font-bold text-slate-900">{app.fertilizer?.nama_pupuk || '-'}</td><td className="p-3 font-semibold">{approved} kg</td><td className="p-3 text-slate-600">Data transaksi</td><td className="p-3 font-semibold text-emerald-700">{approved} kg</td><td className="p-3 text-slate-700">{app.farmer?.nama || '-'}</td><td className="p-3"><StatusBadge status={app.status} /></td></tr>; })}</tbody></table></div>
          {approvedApps.length === 0 && <p className="py-10 text-center text-xs text-slate-400">Belum ada alokasi pupuk yang disetujui.</p>}
        </div>
      )}

      {activeTab === 'monitoring' && (
        <div className="space-y-5">
          <div className="flex flex-wrap gap-2"><select className="px-3 py-2 rounded-xl border border-slate-300 text-xs bg-white"><option>Semua Periode</option><option>Bulan ini</option><option>Tahun ini</option></select><select className="px-3 py-2 rounded-xl border border-slate-300 text-xs bg-white"><option>Semua Jenis Pupuk</option>{Array.from(new Set(applications.map((app) => app.fertilizer?.nama_pupuk).filter(Boolean))).map((name) => <option key={name}>{name}</option>)}</select><select className="px-3 py-2 rounded-xl border border-slate-300 text-xs bg-white"><option>Semua Status</option><option>Disetujui</option><option>Menunggu</option><option>Ditolak</option></select></div>
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">{[['Total Petani', stats?.total_petani || uniqueFarmers.length], ['Total Lahan', uniqueLands.length], ['Total Pengajuan', applications.length], ['Pupuk Disetujui', `${totalApprovedKg} kg`], ['Pupuk Dibuka', 'Terpantau']].map(([label, value]) => <div key={label} className="bg-white rounded-2xl border border-slate-200 p-4"><span className="text-[11px] text-slate-500">{label}</span><strong className="block text-xl font-black text-slate-900 mt-1">{value}</strong></div>)}</div>
          <div className="bg-white rounded-2xl border border-slate-200 p-5"><h3 className="text-sm font-bold text-slate-900 mb-4">Status Pengajuan</h3><div className="space-y-3">{[['Menunggu verifikasi', pendingVerifyApps.length, 'bg-amber-500'], ['Menunggu penugasan', pendingAssignApps.length, 'bg-blue-500'], ['Menunggu approval', pendingFinalApps.length, 'bg-purple-500'], ['Disetujui', approvedApps.length, 'bg-emerald-500']].map(([label, value, color]) => <div key={label} className="flex items-center gap-3 text-xs"><span className="w-32 text-slate-600">{label}</span><div className="h-2 flex-1 rounded-full bg-slate-100 overflow-hidden"><div className={`h-full ${color}`} style={{ width: `${applications.length ? Math.max(8, (value / applications.length) * 100) : 8}%` }} /></div><strong className="w-8 text-right">{value}</strong></div>)}</div></div>
        </div>
      )}

      {activeTab === 'laporan' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs"><div className="mb-5"><h3 className="text-sm font-bold text-slate-900">Laporan Dinas</h3><p className="text-xs text-slate-500 mt-1">Pilih periode dan jenis laporan untuk kebutuhan pelaporan administrasi.</p></div><div className="flex flex-wrap gap-2 mb-5"><input type="date" className="px-3 py-2 rounded-xl border border-slate-300 text-xs" /><span className="self-center text-xs text-slate-400">sampai</span><input type="date" className="px-3 py-2 rounded-xl border border-slate-300 text-xs" /><select className="px-3 py-2 rounded-xl border border-slate-300 text-xs bg-white"><option>Semua Kecamatan</option><option>Mojosari</option><option>Puri</option></select><select className="px-3 py-2 rounded-xl border border-slate-300 text-xs bg-white"><option>Semua Status</option><option>Disetujui</option><option>Ditolak</option></select></div><div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">{['Data Petani', 'Data Lahan', 'Pengajuan & Verifikasi', 'Survei PPL', 'Persetujuan', 'Distribusi', 'Pembukaan Pupuk'].map((report) => <div key={report} className="border border-slate-200 rounded-xl p-4"><FileText className="w-5 h-5 text-emerald-600 mb-2" /><h4 className="text-xs font-bold text-slate-800">Laporan {report}</h4><div className="flex gap-2 mt-3"><button onClick={() => toast.success(`Laporan ${report} siap diekspor sebagai PDF.`)} className="text-[11px] font-bold text-rose-700 hover:underline cursor-pointer">Export PDF</button><button onClick={() => toast.success(`Laporan ${report} siap diekspor sebagai Excel.`)} className="text-[11px] font-bold text-emerald-700 hover:underline cursor-pointer">Export Excel</button></div></div>)}</div></div>
      )}

      {activeTab === 'pengguna' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs"><div className="mb-4"><h3 className="text-sm font-bold text-slate-900">Manajemen Pengguna</h3><p className="text-xs text-slate-500 mt-1">Role sistem: USER / PETANI, PPL, dan ADMIN.</p></div><div className="overflow-x-auto"><table className="w-full text-left text-xs"><thead className="bg-slate-50 text-slate-500 uppercase text-[10px]"><tr><th className="p-3">Nama</th><th className="p-3">Username</th><th className="p-3">Role</th><th className="p-3">Status</th><th className="p-3">Aksi</th></tr></thead><tbody className="divide-y divide-slate-100">{[...uniqueFarmers.map((farmer) => ({ name: farmer.nama, username: farmer.user?.username || '-', role: 'USER / PETANI' })), ...pplOfficers.map((ppl) => ({ name: ppl.username, username: ppl.username, role: 'PPL' }))].map((person, index) => <tr key={`${person.role}-${index}`}><td className="p-3 font-bold text-slate-900">{person.name}</td><td className="p-3 text-slate-600">{person.username}</td><td className="p-3"><span className="px-2 py-1 rounded-full bg-slate-100 text-slate-700 font-bold text-[10px]">{person.role}</span></td><td className="p-3 text-emerald-700 font-bold">Aktif</td><td className="p-3 flex gap-3"><button className="text-emerald-700 font-bold hover:underline cursor-pointer">Detail</button><button className="text-slate-500 font-bold hover:underline cursor-pointer">Edit</button></td></tr>)}</tbody></table></div></div>
      )}

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
                        <p><strong>GPS:</strong> {formatCoord(app.latitude)}, {formatCoord(app.longitude)}</p>
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
                          &ldquo;{app.survey.catatan_ppl}&rdquo;
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
                Setujui Alokasi Pupuk
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
    </div>
  );
}
