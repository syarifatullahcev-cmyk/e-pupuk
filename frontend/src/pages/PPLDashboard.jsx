import React, { useState, useEffect } from 'react';
import { 
  Briefcase, MapPin, CheckCircle2, Camera, Eye, RefreshCw, X,
  ClipboardCheck, LocateFixed, Ruler, Undo2
} from 'lucide-react';
import toast from 'react-hot-toast';
import { filesApi, pplApi } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import PPLBoundaryMap from '../components/PPLBoundaryMap';
import PhotoViewerModal from '../components/PhotoViewerModal';
import KPICard from '../components/KPICard';
import { formatCoord } from '../utils/format';

const EARTH_RADIUS_METERS = 6378137;

function calculatePolygonAreaM2(points) {
  if (points.length < 3) return 0;

  let total = 0;
  points.forEach((point, index) => {
    const nextPoint = points[(index + 1) % points.length];
    const latitude = (value) => (value * Math.PI) / 180;
    total +=
      (latitude(nextPoint[1]) - latitude(point[1])) *
      (2 + Math.sin(latitude(point[0])) + Math.sin(latitude(nextPoint[0])));
  });

  return Math.round(Math.abs((total * EARTH_RADIUS_METERS ** 2) / 2) * 100) / 100;
}

function parsePolygon(value) {
  let polygon = value;
  if (typeof polygon === 'string') {
    try {
      polygon = JSON.parse(polygon);
    } catch {
      return [];
    }
  }
  if (!Array.isArray(polygon)) return [];

  return polygon
    .map((point) => Array.isArray(point)
      ? [Number(point[0]), Number(point[1])]
      : [Number(point?.lat ?? point?.latitude), Number(point?.lng ?? point?.longitude)])
    .filter(([latitude, longitude]) =>
      Number.isFinite(latitude) && Number.isFinite(longitude)
      && latitude >= -90 && latitude <= 90
      && longitude >= -180 && longitude <= 180
    );
}

function getTaskMapCenter(task) {
  const latitude = task.latitude ?? task.land?.latitude;
  const longitude = task.longitude ?? task.land?.longitude;
  if (latitude == null || longitude == null) return null;

  const center = [Number(latitude), Number(longitude)];
  if (
    !Number.isFinite(center[0]) || !Number.isFinite(center[1])
    || center[0] < -90 || center[0] > 90
    || center[1] < -180 || center[1] > 180
  ) {
    return null;
  }
  return center;
}

export default function PPLDashboard() {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTask, setSelectedTask] = useState(null);
  const [showSurveyModal, setShowSurveyModal] = useState(false);
  const [surveyStep, setSurveyStep] = useState('measurement');
  const [startingTaskId, setStartingTaskId] = useState(null);
  const [isUploadingPhotos, setIsUploadingPhotos] = useState(false);

  // Survey Form fields
  const [kondisiLahan, setKondisiLahan] = useState('');
  const [keteranganLahan, setKeteranganLahan] = useState('');
  const [kondisiTanaman, setKondisiTanaman] = useState('');
  const [keteranganTanaman, setKeteranganTanaman] = useState('');
  const [validitasIdentitas, setValiditasIdentitas] = useState('');
  const [verifikasiLahan, setVerifikasiLahan] = useState('');
  const [komoditasAktual, setKomoditasAktual] = useState('');
  const [boundaryPoints, setBoundaryPoints] = useState([]);
  const [fotoSurveiUrls, setFotoSurveiUrls] = useState([]);
  const [catatanPpl, setCatatanPpl] = useState('');
  const [rekomendasi, setRekomendasi] = useState('');

  // Photo viewer state
  const [viewerPhoto, setViewerPhoto] = useState({
    isOpen: false,
    title: '',
    url: '',
    description: '',
  });

  const fetchTasks = async () => {
    setLoading(true);
    try {
      const res = await pplApi.getAssignedTasks();
      const taskData = Array.isArray(res.data) ? res.data : [];
      setTasks(taskData);
      return taskData;
    } catch (e) {
      console.error('Error fetching PPL tasks:', e);
      toast.error(e.response?.data?.detail || 'Gagal memuat daftar tugas PPL.');
      return null;
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  const handleOpenSurvey = (task) => {
    if (task.status !== 'SURVEI_LAPANGAN') {
      toast.error('Mulai survei terlebih dahulu sebelum mengisi laporan.');
      return;
    }

    setSelectedTask(task);
    setSurveyStep('measurement');
    setBoundaryPoints(parsePolygon(task.survey?.polygon_coords));
    setKondisiLahan('');
    setKeteranganLahan('');
    setKondisiTanaman('');
    setKeteranganTanaman('');
    setValiditasIdentitas('');
    setVerifikasiLahan('');
    setKomoditasAktual('');
    setFotoSurveiUrls([]);
    setCatatanPpl('');
    setRekomendasi('');
    setShowSurveyModal(true);
  };

  const handleStartSurvey = async (task) => {
    if (task.status === 'SURVEI_LAPANGAN') {
      handleOpenSurvey(task);
      return;
    }

    setStartingTaskId(task.id);
    try {
      await pplApi.startSurvey(task.id);
      const refreshedTasks = await fetchTasks();
      const updatedTask = refreshedTasks?.find((item) => item.id === task.id)
        || { ...task, status: 'SURVEI_LAPANGAN' };
      handleOpenSurvey(updatedTask);
      toast.success(`Survei pengajuan #${task.id} dimulai.`);
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal memulai survei lapangan.');
    } finally {
      setStartingTaskId(null);
    }
  };

  const handleAddBoundaryPoint = (point) => {
    setBoundaryPoints((points) => [...points, point]);
  };

  const handleAddCurrentLocation = () => {
    if (!navigator.geolocation) {
      toast.error('Browser ini tidak mendukung akses GPS.');
      return;
    }

    navigator.geolocation.getCurrentPosition(
      ({ coords }) => handleAddBoundaryPoint([coords.latitude, coords.longitude]),
      (error) => {
        console.error('Unable to get PPL GPS location:', error);
        toast.error('Lokasi GPS tidak dapat diambil. Periksa izin lokasi perangkat.');
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  const handlePhotoSelection = async (event) => {
    const files = Array.from(event.target.files || []);
    event.target.value = '';
    if (!files.length) return;
    if (fotoSurveiUrls.length + files.length > 5) {
      toast.error('Foto survei maksimal 5 file.');
      return;
    }

    const invalidFile = files.find((file) =>
      !['image/jpeg', 'image/png', 'image/webp'].includes(file.type)
      || file.size > 5 * 1024 * 1024
    );
    if (invalidFile) {
      toast.error('Gunakan foto JPG, PNG, atau WEBP dengan ukuran maksimal 5 MB per file.');
      return;
    }

    setIsUploadingPhotos(true);
    const uploadedUrls = [];
    try {
      for (const file of files) {
        const response = await filesApi.upload(file, 'survei');
        const url = response.data?.url;
        if (typeof url !== 'string' || !url.startsWith('/files/survei/')) {
          throw new Error('Server mengembalikan alamat foto survei yang tidak valid.');
        }
        uploadedUrls.push(url);
      }
      setFotoSurveiUrls((urls) => [...urls, ...uploadedUrls]);
      toast.success(`${uploadedUrls.length} foto survei berhasil diunggah.`);
    } catch (err) {
      if (uploadedUrls.length) {
        setFotoSurveiUrls((urls) => [...urls, ...uploadedUrls]);
      }
      toast.error(err.response?.data?.detail || err.message || 'Gagal mengunggah foto survei.');
    } finally {
      setIsUploadingPhotos(false);
    }
  };

  const handleContinueToReport = () => {
    if (boundaryPoints.length < 3 || calculatePolygonAreaM2(boundaryPoints) <= 0) {
      toast.error('Tambahkan minimal 3 titik batas yang membentuk bidang lahan.');
      return;
    }
    setSurveyStep('report');
  };

  const handleSubmitSurvey = async (e) => {
    e.preventDefault();
    if (!selectedTask) return;
    if (boundaryPoints.length < 3 || calculatePolygonAreaM2(boundaryPoints) <= 0) {
      toast.error('Poligon batas lahan belum valid.');
      setSurveyStep('measurement');
      return;
    }
    if (fotoSurveiUrls.length < 2 || fotoSurveiUrls.length > 5) {
      toast.error('Unggah minimal 2 dan maksimal 5 foto bukti survei.');
      return;
    }

    const toastId = toast.loading('Mengirim laporan survei...');
    try {
      await pplApi.submitSurvey(selectedTask.id, {
        kondisi_fisik_lahan: kondisiLahan,
        keterangan_fisik_lahan: [
          `Pemeriksaan identitas: ${validitasIdentitas}`,
          `Verifikasi lahan: ${verifikasiLahan}`,
          keteranganLahan.trim(),
        ].filter(Boolean).join('. '),
        kondisi_tanaman: kondisiTanaman,
        keterangan_tanaman: [
          `Komoditas aktual: ${komoditasAktual.trim()}`,
          keteranganTanaman.trim(),
        ].filter(Boolean).join('. '),
        luas_lahan_aktual_m2: calculatePolygonAreaM2(boundaryPoints),
        polygon_coords: boundaryPoints,
        foto_survei_urls: fotoSurveiUrls,
        catatan_ppl: catatanPpl,
        rekomendasi: rekomendasi,
      });

      setShowSurveyModal(false);
      await fetchTasks();
      toast.success(`✅ Hasil survei lapangan untuk pengajuan #${selectedTask.id} berhasil diserahkan ke Admin Dinas Pertanian!`, { id: toastId, duration: 5000 });
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal menyimpan hasil survei lapangan.', { id: toastId });
    }
  };

  const pendingTasks = tasks.filter((t) => t.status === 'DITUGASKAN_KE_PPL' || t.status === 'SURVEI_LAPANGAN');
  const completedTasks = tasks.filter((t) => t.status === 'MENUNGGU_PERSETUJUAN_AKHIR');

  if (loading) {
    return (
      <div className="space-y-8 pb-16 animate-pulse">
        <div className="rounded-3xl bg-blue-100 h-36" />
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
          {[...Array(3)].map((_, i) => <div key={i} className="h-28 bg-slate-200 rounded-2xl" />)}
        </div>
        <div className="space-y-4">
          {[...Array(2)].map((_, i) => <div key={i} className="h-48 bg-slate-200 rounded-2xl" />)}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 pb-16">
      {/* Top Banner */}
      <div className="rounded-3xl bg-gradient-to-r from-blue-900 via-sky-900 to-slate-900 text-white p-6 sm:p-8 relative overflow-hidden shadow-xl border border-sky-800/40">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <div className="flex items-center gap-2 text-sky-300 text-xs font-bold uppercase tracking-wider mb-2">
              <Briefcase className="w-4 h-4" /> Penyuluh Pertanian Lapangan (PPL) Mojokerto
            </div>
            <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
              Tugas Survei Fisik Lapangan
            </h1>
            <p className="mt-1 text-xs sm:text-sm text-sky-100 max-w-2xl leading-relaxed">
              Lakukan inspeksi fisik langsung ke sawah dan ladang petani sesuai disposisi Admin. Periksa kesesuaian jenis tanaman, kondisi tanah, dan unggah dokumentasi foto bukti survei.
            </p>
          </div>

          <button
            onClick={fetchTasks}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-sky-800/80 hover:bg-sky-700 text-white text-xs font-bold border border-sky-600/50 transition-colors shrink-0 cursor-pointer"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            <span>Segarkan Tugas</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5">
        <KPICard
          title="Tugas Survei Aktif"
          value={pendingTasks.length}
          subtitle="Perlu Dilakukan Kunjungan Lapangan"
          icon={Briefcase}
          color="blue"
          badge="Prioritas"
        />
        <KPICard
          title="Survei Telah Diserahkan"
          value={completedTasks.length}
          subtitle="Menunggu Keputusan Final Admin"
          icon={CheckCircle2}
          color="emerald"
          badge="Selesai PPL"
        />
        <KPICard
          title="Wilayah Tugas Binaan"
          value="Mojokerto"
          subtitle="Kec. Mojosari & Trowulan"
          icon={MapPin}
          color="purple"
          badge="Wilayah"
        />
      </div>

      {/* Tasks List */}
      <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-6">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div>
            <h3 className="text-base font-bold text-slate-900">
              Daftar Tugas Survei Fisik Lahan ({pendingTasks.length} Aktif)
            </h3>
            <p className="text-xs text-slate-500 mt-0.5">
              Klik "Input Hasil Survei" setelah menyelesaikan pemeriksaan fisik di lapangan
            </p>
          </div>
        </div>

        {pendingTasks.length === 0 ? (
          <div className="p-12 text-center">
            <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
            <p className="text-sm font-bold text-slate-800">Semua Tugas Survei Selesai!</p>
            <p className="text-xs text-slate-400 mt-1">
              Saat ini tidak ada penugasan survei baru dari Admin Dinas Pertanian.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-5">
            {pendingTasks.map((task) => (
              <div
                key={task.id}
                className="rounded-2xl border border-slate-200 bg-white p-5 hover:border-sky-300 transition-all shadow-xs space-y-4"
              >
                {/* Header */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-xs font-bold text-slate-400">#{task.id}</span>
                      <h4 className="text-base font-bold text-slate-900">
                        {task.farmer?.nama} — Pengajuan {task.jumlah_diajukan} kg {task.fertilizer?.nama_pupuk}
                      </h4>
                      <StatusBadge status={task.status} />
                    </div>
                    <p className="text-xs text-slate-500 mt-1">
                      Petani: {task.farmer?.nama} ({task.farmer?.kontak || '08xx'}) | Kelompok: {task.farmer?.farmer_group?.nama_kelompok || 'Poktan'}
                    </p>
                  </div>

                  <button
                    onClick={() => handleStartSurvey(task)}
                    disabled={startingTaskId === task.id}
                    className="px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-sm shadow-blue-200 cursor-pointer shrink-0 disabled:opacity-60 disabled:cursor-wait"
                  >
                    {startingTaskId === task.id
                      ? <RefreshCw className="w-4 h-4 animate-spin" />
                      : task.status === 'SURVEI_LAPANGAN'
                        ? <Camera className="w-4 h-4" />
                        : <Ruler className="w-4 h-4" />}
                    {task.status === 'SURVEI_LAPANGAN' ? 'Lanjutkan Survei' : 'Mulai Survei'}
                  </button>
                </div>

                {/* Location & Farm Details */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs bg-slate-50 rounded-xl p-4 border border-slate-200/70">
                  <div>
                    <span className="text-slate-400 block text-[10px] uppercase font-bold">Lokasi & Alamat Lahan</span>
                    <p className="font-semibold text-slate-800 mt-0.5">{task.alamat_lahan}</p>
                    <span className="text-[11px] text-slate-500 font-mono mt-0.5 block">
                      GPS: {formatCoord(task.latitude)}, {formatCoord(task.longitude)}
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-400 block text-[10px] uppercase font-bold">Komoditas & Luas Terdaftar</span>
                    <p className="font-semibold text-slate-800 mt-0.5">
                      {task.land?.commodity?.nama_komoditas || 'Padi'}
                    </p>
                    <span className="text-[11px] text-slate-500">
                      Luas Pengajuan: <strong>{task.land?.luas_m2} m²</strong>
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-400 block text-[10px] uppercase font-bold">Foto Lahan Referensi</span>
                    {task.foto_lahan_snapshot_url && (
                      <button
                        type="button"
                        onClick={() => setViewerPhoto({
                          isOpen: true,
                          title: `Foto Lahan Pengajuan #${task.id}`,
                          url: task.foto_lahan_snapshot_url,
                          description: task.alamat_lahan
                        })}
                        className="mt-1 text-blue-700 hover:text-blue-800 font-bold flex items-center gap-1 text-[11px]"
                      >
                        <Eye className="w-3.5 h-3.5" /> Lihat Foto Referensi Petani
                      </button>
                    )}
                  </div>
                </div>

                {/* Admin Assignment Notes */}
                {task.catatan_penugasan && (
                  <div className="text-xs p-3 rounded-xl bg-sky-50 text-sky-900 border border-sky-200">
                    <strong className="font-bold">Instruksi Khusus Admin: </strong>
                    <span>{task.catatan_penugasan}</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Completed Tasks Section — Riwayat Survei Diserahkan */}
      {completedTasks.length > 0 && (
        <div className="bg-white rounded-2xl p-6 border border-emerald-200 shadow-xs space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2">
              <ClipboardCheck className="w-5 h-5 text-emerald-600" />
              <div>
                <h3 className="text-base font-bold text-slate-900">
                  Riwayat Survei Diserahkan ({completedTasks.length})
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Laporan telah dikirim — menunggu persetujuan akhir Admin Dinas Pertanian
                </p>
              </div>
            </div>
            <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800 border border-emerald-200">
              Selesai PPL
            </span>
          </div>

          <div className="grid grid-cols-1 gap-4">
            {completedTasks.map((task) => (
              <div
                key={task.id}
                className="rounded-xl border border-emerald-100 bg-emerald-50/30 p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
              >
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                    <span className="font-mono text-xs font-bold text-slate-400">#{task.id}</span>
                    <h4 className="text-sm font-bold text-slate-900">
                      {task.farmer?.nama} — {task.jumlah_diajukan} kg {task.fertilizer?.nama_pupuk}
                    </h4>
                  </div>
                  <p className="text-xs text-slate-500 ml-6 flex items-center gap-1">
                    <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                    {task.alamat_lahan}
                  </p>
                  {task.survey && (
                    <div className="ml-6 flex flex-wrap gap-2 text-[11px]">
                      <span className="px-2 py-0.5 rounded-md bg-emerald-100 text-emerald-800 font-semibold border border-emerald-200">
                        Kondisi: {task.survey.kondisi_fisik_lahan}
                      </span>
                      <span className={`px-2 py-0.5 rounded-md font-semibold border ${
                        task.survey.rekomendasi === 'SETUJU'
                          ? 'bg-emerald-100 text-emerald-800 border-emerald-200'
                          : 'bg-rose-100 text-rose-800 border-rose-200'
                      }`}>
                        Rekomendasi: {task.survey.rekomendasi}
                      </span>
                    </div>
                  )}
                </div>
                <StatusBadge status={task.status} />
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Modal: Input Hasil Survei Lapangan PPL */}
      {showSurveyModal && selectedTask && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-3xl w-full overflow-hidden max-h-[92vh] flex flex-col">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-sky-50">
              <div>
                <h3 className="text-base font-bold text-sky-950">Survei Lapangan #{selectedTask.id}</h3>
                <p className="text-xs text-sky-700">
                  Petani: {selectedTask.farmer?.nama} | Lahan: {selectedTask.alamat_lahan}
                </p>
              </div>
              <button
                onClick={() => setShowSurveyModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {surveyStep === 'measurement' ? (
              <div className="p-6 overflow-y-auto space-y-4">
                <div>
                  <h4 className="text-sm font-bold text-slate-900">Tahap 1 — Pengukuran Batas Lahan</h4>
                  <p className="mt-1 text-xs text-slate-500">
                    Klik peta untuk menambahkan titik batas, atau rekam titik GPS saat berada di patok. Minimal 3 titik diperlukan.
                  </p>
                </div>
                <PPLBoundaryMap
                  center={getTaskMapCenter(selectedTask)}
                  points={boundaryPoints}
                  onAddPoint={handleAddBoundaryPoint}
                />
                <div className="flex flex-wrap items-center gap-2">
                  <button
                    type="button"
                    onClick={handleAddCurrentLocation}
                    className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-xs font-bold text-white hover:bg-emerald-700"
                  >
                    <LocateFixed className="h-4 w-4" /> Tambah Titik GPS
                  </button>
                  <button
                    type="button"
                    onClick={() => setBoundaryPoints((points) => points.slice(0, -1))}
                    disabled={!boundaryPoints.length}
                    className="inline-flex items-center gap-2 rounded-lg border border-slate-300 px-3 py-2 text-xs font-bold text-slate-700 disabled:opacity-50"
                  >
                    <Undo2 className="h-4 w-4" /> Hapus Titik Terakhir
                  </button>
                  <span className="text-xs text-slate-500">{boundaryPoints.length} titik</span>
                </div>
                <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 text-xs">
                  <p className="font-semibold text-slate-700">Luas hasil ukur</p>
                  <p className="mt-1 text-lg font-black text-emerald-700">
                    {calculatePolygonAreaM2(boundaryPoints).toLocaleString('id-ID')} m²
                  </p>
                  <p className="mt-1 text-slate-500">
                    Luas terdaftar: {Number(selectedTask.land?.luas_m2 || 0).toLocaleString('id-ID')} m²
                  </p>
                </div>
                <div className="flex justify-end gap-3 border-t border-slate-100 pt-4">
                  <button
                    type="button"
                    onClick={() => setShowSurveyModal(false)}
                    className="rounded-xl border border-slate-300 px-4 py-2 text-xs font-bold text-slate-600 hover:bg-slate-100"
                  >
                    Batal
                  </button>
                  <button
                    type="button"
                    onClick={handleContinueToReport}
                    className="rounded-xl bg-blue-600 px-5 py-2 text-xs font-bold text-white hover:bg-blue-700"
                  >
                    Lanjut ke Laporan
                  </button>
                </div>
              </div>
            ) : (
            <form onSubmit={handleSubmitSurvey} className="p-6 overflow-y-auto space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-sm font-bold text-slate-900">Tahap 2 — Laporan Hasil Survei</h4>
                  <p className="text-xs text-slate-500">
                    Luas terukur: {calculatePolygonAreaM2(boundaryPoints).toLocaleString('id-ID')} m²
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => setSurveyStep('measurement')}
                  className="text-xs font-bold text-blue-700 hover:text-blue-800"
                >
                  Ubah Pengukuran
                </button>
              </div>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Kesesuaian Identitas Petani <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={validitasIdentitas}
                    onChange={(e) => setValiditasIdentitas(e.target.value)}
                    required
                    className="w-full rounded-xl border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-800"
                  >
                    <option value="">Pilih hasil pemeriksaan</option>
                    <option value="SESUAI">Sesuai</option>
                    <option value="TIDAK_SESUAI">Tidak sesuai</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Verifikasi Kesesuaian Lahan <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={verifikasiLahan}
                    onChange={(e) => setVerifikasiLahan(e.target.value)}
                    required
                    className="w-full rounded-xl border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-800"
                  >
                    <option value="">Pilih hasil pemeriksaan</option>
                    <option value="SESUAI">Sesuai</option>
                    <option value="TIDAK_SESUAI">Tidak sesuai</option>
                  </select>
                </div>
                <div className="sm:col-span-2">
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Komoditas Aktual <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={komoditasAktual}
                    onChange={(e) => setKomoditasAktual(e.target.value)}
                    required
                    placeholder="Catat komoditas yang ditemukan di lahan"
                    className="w-full rounded-xl border border-slate-300 px-3 py-2 text-xs text-slate-800"
                  />
                </div>
              </div>
              {/* Kondisi Fisik Lahan */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Kondisi Fisik Lahan <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={kondisiLahan}
                    onChange={(e) => setKondisiLahan(e.target.value)}
                    required
                    className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-sky-500 outline-hidden font-semibold"
                  >
                    <option value="">Pilih kondisi lahan</option>
                    <option value="BAIK">BAIK (Subur, irigasi aktif)</option>
                    <option value="CUKUP">CUKUP (Perlu perbaikan ringan)</option>
                    <option value="TIDAK_LAYAK">TIDAK_LAYAK (Lahan tidur / bukan sawah)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Kesesuaian Tanaman <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={kondisiTanaman}
                    onChange={(e) => setKondisiTanaman(e.target.value)}
                    required
                    className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-sky-500 outline-hidden font-semibold"
                  >
                    <option value="">Pilih kesesuaian tanaman</option>
                    <option value="SESUAI">SESUAI (Cocok dengan alokasi pupuk)</option>
                    <option value="TIDAK_SESUAI">TIDAK_SESUAI (Jenis tanaman berbeda)</option>
                  </select>
                </div>
              </div>

              {/* Keterangan detail */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Keterangan Fisik Lahan
                  </label>
                  <input
                    type="text"
                    value={keteranganLahan}
                    onChange={(e) => setKeteranganLahan(e.target.value)}
                    placeholder="Contoh: Tanah gembur, saluran air lancar"
                    className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-sky-500 outline-hidden"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Keterangan Kondisi Tanaman
                  </label>
                  <input
                    type="text"
                    value={keteranganTanaman}
                    onChange={(e) => setKeteranganTanaman(e.target.value)}
                    placeholder="Contoh: Padi umur 2 minggu, serempak"
                    className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-sky-500 outline-hidden"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Foto Bukti Survei (minimal 2, maksimal 5; JPG/PNG/WEBP, maks. 5 MB per foto) <span className="text-rose-500">*</span>
                </label>
                <input
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  multiple
                  disabled={isUploadingPhotos || fotoSurveiUrls.length >= 5}
                  onChange={handlePhotoSelection}
                  className="block w-full text-xs text-slate-600 file:mr-3 file:rounded-lg file:border-0 file:bg-emerald-50 file:px-3 file:py-2 file:text-xs file:font-bold file:text-emerald-700 disabled:opacity-50"
                />
                {isUploadingPhotos && <p className="mt-2 text-xs text-blue-700">Mengunggah foto...</p>}
                <div className="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-5">
                  {fotoSurveiUrls.map((url) => (
                    <div key={url} className="relative">
                      <img src={url} alt="Bukti survei lapangan" className="h-20 w-full rounded-lg border border-slate-200 object-cover" />
                      <button
                        type="button"
                        onClick={() => setFotoSurveiUrls((urls) => urls.filter((item) => item !== url))}
                        className="absolute right-1 top-1 rounded-full bg-white/90 p-1 text-rose-600"
                        aria-label="Hapus foto survei"
                      >
                        <X className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  ))}
                </div>
                {fotoSurveiUrls.length < 2 && (
                  <p className="mt-1 text-xs text-amber-700">Masih perlu {2 - fotoSurveiUrls.length} foto bukti.</p>
                )}
              </div>

              {/* Catatan PPL & Rekomendasi */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Catatan Kesimpulan PPL
                </label>
                <textarea
                  rows={2}
                  value={catatanPpl}
                  onChange={(e) => setCatatanPpl(e.target.value)}
                  required
                  placeholder="Catatan tambahan untuk pertimbangan Admin Dinas..."
                  className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-sky-500 outline-hidden"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Rekomendasi Akhir PPL <span className="text-rose-500">*</span>
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={() => setRekomendasi('SETUJU')}
                    className={`py-2.5 px-4 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
                      rekomendasi === 'SETUJU'
                        ? 'bg-emerald-600 text-white border-emerald-600 shadow-sm shadow-emerald-200'
                        : 'bg-white text-slate-700 border-slate-300 hover:bg-slate-50'
                    }`}
                  >
                    ✓ Rekomendasikan SETUJU
                  </button>

                  <button
                    type="button"
                    onClick={() => setRekomendasi('TOLAK')}
                    className={`py-2.5 px-4 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
                      rekomendasi === 'TOLAK'
                        ? 'bg-rose-600 text-white border-rose-600 shadow-sm shadow-rose-200'
                        : 'bg-white text-slate-700 border-slate-300 hover:bg-slate-50'
                    }`}
                  >
                    ✕ Rekomendasikan TOLAK
                  </button>
                </div>
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowSurveyModal(false)}
                  className="px-4 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isUploadingPhotos || !rekomendasi}
                  className="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-md shadow-blue-200 cursor-pointer disabled:opacity-50"
                >
                  Kirim Laporan Survei
                </button>
              </div>
            </form>
            )}
          </div>
        </div>
      )}

      {/* Photo Viewer Modal */}
      <PhotoViewerModal
        isOpen={viewerPhoto.isOpen}
        onClose={() => setViewerPhoto({ ...viewerPhoto, isOpen: false })}
        title={viewerPhoto.title}
        imageUrl={viewerPhoto.url}
        description={viewerPhoto.description}
      />
    </div>
  );
}
