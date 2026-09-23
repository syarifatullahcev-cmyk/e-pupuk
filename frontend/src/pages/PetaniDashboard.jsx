import React, { useState, useEffect } from 'react';
import { 
  LayoutDashboard, User, Tractor, MapPin, Calendar, FileText, QrCode, 
  AlertTriangle, RefreshCw, Eye, CheckCircle2, ChevronRight,
  ShieldCheck, ArrowUpRight, Sparkles, X, Map, Download, Plus,
  PieChart, History, PlusCircle, LogOut, Check, Layers, PackageCheck,
  Crosshair, Navigation, Compass, Shield, Smartphone, Clock, ArrowRight,
  Camera, CheckCircle, XCircle
} from 'lucide-react';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';
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

// Helper Haversine Distance (in meters)
function calculateHaversineMeters(lat1, lon1, lat2, lon2) {
  if (lat1 === null || lat1 === undefined || lon1 === null || lon1 === undefined ||
      lat2 === null || lat2 === undefined || lon2 === null || lon2 === undefined) {
    return 999999;
  }
  const R = 6371e3; // meters
  const dLat = ((Number(lat2) - Number(lat1)) * Math.PI) / 180;
  const dLon = ((Number(lon2) - Number(lon1)) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((Number(lat1) * Math.PI) / 180) *
      Math.cos((Number(lat2) * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c);
}

// Initial Sample History (as required)
const DEFAULT_SAMPLE_HISTORY = [
  {
    id: 'HIST-2026-001',
    id_pupuk: 'EPU-000123',
    tanggal: '22 September 2026',
    waktu: '08:42 WIB',
    jenis_pupuk: 'Urea Bersubsidi',
    jumlah_pupuk: '70 kg',
    jumlah_kg: 70,
    nama_lahan: 'Sawah Blok Timur Kebondalem',
    alamat_lahan: 'Dusun Kebondalem RT 02/RW 03, Mojokerto',
    latitude: -7.531234,
    longitude: 112.551234,
    jarak_meter: 18,
    status_pembukaan: 'Pembukaan Berhasil',
    status_validasi: 'VALID',
    verifikasi_lokasi: 'Lokasi sesuai dengan lahan terdaftar'
  },
  {
    id: 'HIST-2026-002',
    id_pupuk: 'EPU-000124',
    tanggal: '18 September 2026',
    waktu: '09:15 WIB',
    jenis_pupuk: 'NPK Phonska',
    jumlah_pupuk: '50 kg',
    jumlah_kg: 50,
    nama_lahan: 'Sawah Blok Timur Kebondalem',
    alamat_lahan: 'Dusun Kebondalem RT 02/RW 03, Mojokerto',
    latitude: -7.531234,
    longitude: 112.551234,
    jarak_meter: 24,
    status_pembukaan: 'Pembukaan Berhasil',
    status_validasi: 'VALID',
    verifikasi_lokasi: 'Lokasi sesuai dengan lahan terdaftar'
  }
];

export default function PetaniDashboard() {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  // Active Navigation Tab
  // Options: 'dashboard', 'profil', 'lahan', 'pengajuan', 'status', 'kuota', 'pembukaan', 'riwayat'
  const [activeNav, setActiveNav] = useState('dashboard');

  // Core Data
  const [stats, setStats] = useState(null);
  const [farmer, setFarmer] = useState(null);
  const [lands, setLands] = useState([]);
  const [applications, setApplications] = useState([]);
  const [fertilizers, setFertilizers] = useState([]);
  const [commodities, setCommodities] = useState([]);
  const [historyList, setHistoryList] = useState(DEFAULT_SAMPLE_HISTORY);
  const [loading, setLoading] = useState(true);

  // Modals state
  const [showApplyModal, setShowApplyModal] = useState(false);
  const [showReviseModal, setShowReviseModal] = useState(false);
  const [showAddLandModal, setShowAddLandModal] = useState(false);
  const [selectedLandDetail, setSelectedLandDetail] = useState(null);
  const [selectedHistoryDetail, setSelectedHistoryDetail] = useState(null);
  const [selectedApp, setSelectedApp] = useState(null);

  // Lightbox / Photo Viewer Modal
  const [viewerPhoto, setViewerPhoto] = useState({
    isOpen: false,
    title: '',
    url: '',
    secondaryUrl: '',
    secondaryTitle: '',
    description: '',
  });

  // Application Form State
  const [formData, setFormData] = useState({
    land_id: '',
    fertilizer_id: '',
    jumlah_diajukan: '',
    alamat_lahan: '',
    latitude: -7.531234,
    longitude: 112.551234,
  });

  // Add Land Form State
  const [landFormData, setLandFormData] = useState({
    lokasi_deskripsi: '',
    luas_m2: '',
    commodity_id: '',
    alamat_lahan: '',
    status_kepemilikan: 'MILIK',
    latitude: -7.531234,
    longitude: 112.551234,
    foto_lahan_url: '/files/lahan/sample_lahan1.jpg',
  });

  // Revise Documents Form State
  const [reviseKtpUrl, setReviseKtpUrl] = useState(null);
  const [reviseLahanUrl, setReviseLahanUrl] = useState(null);

  // =========================================================================
  // STATE SCANNER QR KARUNG PUPUK FISIK & GEOFENCING GPS
  // =========================================================================
  // Step: 'select' | 'gps' | 'scan' | 'result' | 'success'
  const [pembukaanStep, setPembukaanStep] = useState('select');
  const [selectedAllocation, setSelectedAllocation] = useState(null);
  const [isScannerActive, setIsScannerActive] = useState(false);
  const [manualInputId, setManualInputId] = useState('');
  const [scannedBag, setScannedBag] = useState(null);
  const [qrValidation, setQrValidation] = useState({
    isScanned: false,
    isValidQr: false,
    isAlreadyUsed: false,
    isAllocationMatch: true,
    message: '',
  });

  // GPS State
  const [currentGps, setCurrentGps] = useState({
    latitude: -7.531234,
    longitude: 112.551234,
    accuracy: 12,
    timestamp: 'Baru saja',
  });
  const [gpsLoading, setGpsLoading] = useState(false);
  const [gpsError, setGpsError] = useState(null);
  const [isSimulatedAtLand, setIsSimulatedAtLand] = useState(true); // default true for demo convenience
  const [simulatedCustomDistance, setSimulatedCustomDistance] = useState(18); // default 18m
  const [isProcessingOpen, setIsProcessingOpen] = useState(false);
  const [openSuccessState, setOpenSuccessState] = useState(null); // stores final success data

  // Mock allocation list — in production this comes from approved applications
  const MOCK_ALLOCATIONS = [
    {
      id: 'ALOK-2026-001',
      jenis_pupuk: 'Urea Bersubsidi',
      jumlah_kg: 70,
      nama_lahan: 'Sawah Blok Timur Kebondalem',
      alamat_lahan: 'Dusun Kebondalem RT 02/RW 03, Mojokerto',
      status: 'Siap Dibuka',
      latitude: -7.531200,
      longitude: 112.551210,
    },
    {
      id: 'ALOK-2026-002',
      jenis_pupuk: 'NPK Phonska Bersubsidi',
      jumlah_kg: 50,
      nama_lahan: 'Sawah Blok Barat Mojosari',
      alamat_lahan: 'Desa Mojosari, Kecamatan Mojosari, Mojokerto',
      status: 'Siap Dibuka',
      latitude: -7.528000,
      longitude: 112.548500,
    },
  ];

  // Fetch Dashboard Data
  const fetchData = async () => {
    setLoading(true);
    try {
      const [fRes, landsRes, appsRes, fertsRes, statsRes, comRes] = await Promise.all([
        farmersApi.getMe(),
        landsApi.getAll(),
        applicationsApi.getAll(),
        farmersApi.getFertilizers(),
        applicationsApi.getPetaniStats(),
        farmersApi.getCommodities().catch(() => ({ data: [] })),
      ]);

      setFarmer(fRes.data);
      setLands(landsRes.data || []);
      setApplications(appsRes.data || []);
      setFertilizers(fertsRes.data || []);
      setStats(statsRes.data || null);
      setCommodities(comRes.data || []);

      if (landsRes.data && landsRes.data.length > 0) {
        setFormData((prev) => ({
          ...prev,
          land_id: landsRes.data[0].id,
          alamat_lahan: landsRes.data[0].alamat_lahan,
          latitude: landsRes.data[0].latitude || -7.531234,
          longitude: landsRes.data[0].longitude || 112.551234,
        }));
      }
      if (fertsRes.data && fertsRes.data.length > 0) {
        setFormData((prev) => ({ ...prev, fertilizer_id: fertsRes.data[0].id }));
      }

      // Fetch dynamic scans from backend if any
      try {
        const scansRes = await distributionsApi.getMyScans();
        if (scansRes.data && scansRes.data.length > 0) {
          const existingIds = new Set(scansRes.data.map((s) => s.id));
          const uniqueDefault = DEFAULT_SAMPLE_HISTORY.filter((d) => !existingIds.has(d.id));
          setHistoryList([...scansRes.data, ...uniqueDefault]);
        }
      } catch (err) {
        // Fallback to sample history
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

  // Handle Geolocation from Browser / Device
  const requestRealGps = () => {
    setGpsLoading(true);
    setGpsError(null);
    if (!navigator.geolocation) {
      setGpsError('Perangkat atau browser Anda tidak mendukung GPS Geolocation.');
      setGpsLoading(false);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const lat = Number(pos.coords.latitude.toFixed(6));
        const lng = Number(pos.coords.longitude.toFixed(6));
        const acc = Math.round(pos.coords.accuracy || 15);
        setCurrentGps({
          latitude: lat,
          longitude: lng,
          accuracy: acc,
          timestamp: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) + ' WIB',
        });
        setIsSimulatedAtLand(false);
        setGpsLoading(false);
        toast.success(`GPS Terdeteksi: Lat ${lat}, Lng ${lng} (Akurasi: ±${acc}m)`);
      },
      (err) => {
        setGpsLoading(false);
        let msg = 'Gagal mengakses GPS perangkat.';
        if (err.code === 1) msg = 'Izin akses lokasi GPS ditolak oleh pengguna.';
        else if (err.code === 2) msg = 'Posisi GPS tidak dapat ditemukan.';
        else if (err.code === 3) msg = 'Waktu permintaan GPS habis (timeout).';
        setGpsError(msg);
        toast.error(msg);
      },
      { enableHighAccuracy: true, timeout: 12000, maximumAge: 0 }
    );
  };

  // Target Land Coordinates (First land or selected application land)
  const targetLand = lands[0] || {
    lokasi_deskripsi: 'Sawah Blok Timur Kebondalem',
    latitude: -7.531200,
    longitude: 112.551210,
  };

  const targetLandLat = targetLand.latitude || -7.531200;
  const targetLandLon = targetLand.longitude || 112.551210;

  // Use selectedAllocation land coords (or fall back to first land)
  const activeAllocLat = selectedAllocation?.latitude || targetLandLat;
  const activeAllocLon = selectedAllocation?.longitude || targetLandLon;

  const realDistanceToAlloc = calculateHaversineMeters(
    currentGps.latitude, currentGps.longitude,
    activeAllocLat, activeAllocLon
  );
  const displayedDistance = isSimulatedAtLand ? simulatedCustomDistance : realDistanceToAlloc;
  const isLocationValid = displayedDistance <= 100; // 100m radius threshold

  // Reset pembukaan flow to initial state
  const resetPembukaanFlow = () => {
    setPembukaanStep('select');
    setSelectedAllocation(null);
    setIsScannerActive(false);
    setManualInputId('');
    setScannedBag(null);
    setQrValidation({ isScanned: false, isValidQr: false, isAlreadyUsed: false, isAllocationMatch: true, message: '' });
    setOpenSuccessState(null);
    setIsSimulatedAtLand(true);
    setSimulatedCustomDistance(18);
    setGpsError(null);
  };

  // Handler for Scanning Physical Bag QR Code
  const handleScanBagId = (bagIdToUse) => {
    const rawCode = (bagIdToUse || manualInputId || '').trim().toUpperCase();
    if (!rawCode) {
      toast.error('Masukkan atau pindai ID QR Pupuk pada karung.');
      return;
    }

    // Check validation scenarios
    if (rawCode === 'EPU-000099') {
      // Already used bag
      setScannedBag({
        idPupuk: 'EPU-000099',
        jenisPupuk: 'Urea Bersubsidi',
        beratKg: 50,
        statusBag: 'Sudah Dibuka',
        waktuDigunakan: '18 September 2026, 07:30 WIB',
      });
      setQrValidation({
        isScanned: true,
        isValidQr: false,
        isAlreadyUsed: true,
        message: 'Karung pupuk ini sudah pernah dibuka pada 18 September 2026. Tidak dapat digunakan kembali.',
      });
      setIsScannerActive(false);
      setPembukaanStep('result');
      toast.error('QR Pupuk Sudah Pernah Digunakan!');
      return;
    }

    if (rawCode === 'EPU-INVALID' || (rawCode.length < 5 && !rawCode.startsWith('EPU'))) {
      // Unrecognized QR
      setScannedBag(null);
      setQrValidation({
        isScanned: true,
        isValidQr: false,
        isAlreadyUsed: false,
        message: 'QR Code tidak terdaftar dalam sistem E-PUPUK. Pastikan memindai QR yang tercetak pada karung pupuk bersubsidi.',
      });
      setIsScannerActive(false);
      setPembukaanStep('result');
      toast.error('QR Pupuk Tidak Valid!');
      return;
    }

    // Valid physical bag QR Code (e.g., EPU-000123 or EPU-000124)
    const isNpk = rawCode.includes('124') || rawCode.toLowerCase().includes('npk');
    const weight = isNpk ? 50 : 70;
    const fertName = isNpk ? 'NPK Phonska Bersubsidi' : 'Urea Bersubsidi';

    // Check if bag matches selected allocation
    const isAllocMatch = !selectedAllocation || 
      (isNpk && (selectedAllocation.jenis_pupuk.toLowerCase().includes('npk') || selectedAllocation.jenis_pupuk.toLowerCase().includes('phonska'))) ||
      (!isNpk && selectedAllocation.jenis_pupuk.toLowerCase().includes('urea'));

    setScannedBag({
      idPupuk: rawCode,
      jenisPupuk: fertName,
      beratKg: weight,
      statusBag: 'SIAP DIBUKA',
      isAllocationMatch: isAllocMatch,
    });

    setQrValidation({
      isScanned: true,
      isValidQr: true,
      isAlreadyUsed: false,
      isAllocationMatch: isAllocMatch,
      message: isAllocMatch
        ? 'QR Pupuk valid & pupuk sesuai alokasi petani'
        : `Peringatan: Jenis pupuk karung (${fertName}) tidak cocok dengan alokasi yang dipilih (${selectedAllocation?.jenis_pupuk})`,
    });

    setIsScannerActive(false);
    setPembukaanStep('result');
    if (isAllocMatch) {
      toast.success(`QR Pupuk ${rawCode} Berhasil Dipindai!`);
    } else {
      toast.error(`Jenis pupuk tidak sesuai alokasi (${fertName})!`);
    }
  };

  // Confirm Pembukaan Pupuk Handler
  const handleConfirmPembukaanPupuk = async () => {
    if (!scannedBag || !qrValidation.isValidQr) {
      toast.error('QR Pupuk belum valid.');
      return;
    }

    if (!isLocationValid) {
      toast.error(`Pembukaan Ditolak: Anda berada ${displayedDistance} meter dari titik lahan.`);
      return;
    }

    setIsProcessingOpen(true);
    const toastId = toast.loading('Memvalidasi & mengonfirmasi pembukaan karung pupuk...');

    const latToUse = isSimulatedAtLand ? activeAllocLat : currentGps.latitude;
    const lngToUse = isSimulatedAtLand ? activeAllocLon : currentGps.longitude;

    try {
      // Send scan data to backend
      await distributionsApi.scanQr({
        qr_token: scannedBag.idPupuk,
        latitude: latToUse,
        longitude: lngToUse,
      }).catch(() => null); // mock fallback if backend token differs

      const now = new Date();
      const dateStr = now.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
      const timeStr = now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB';

      const landName = selectedAllocation?.nama_lahan || targetLand.lokasi_deskripsi || 'Sawah Blok Timur Kebondalem';
      const landAddr = selectedAllocation?.alamat_lahan || targetLand.alamat_lahan || 'Kabupaten Mojokerto';

      const newHistoryItem = {
        id: `HIST-${Date.now()}`,
        id_pupuk: scannedBag.idPupuk,
        tanggal: dateStr,
        waktu: timeStr,
        jenis_pupuk: scannedBag.jenisPupuk,
        jumlah_pupuk: `${scannedBag.beratKg} kg`,
        jumlah_kg: scannedBag.beratKg,
        nama_lahan: landName,
        alamat_lahan: landAddr,
        latitude: latToUse,
        longitude: lngToUse,
        jarak_meter: displayedDistance,
        status_pembukaan: 'Pembukaan Berhasil',
        status_validasi: 'VALID',
        verifikasi_lokasi: 'Lokasi sesuai dengan lahan terdaftar'
      };

      setHistoryList([newHistoryItem, ...historyList]);
      setOpenSuccessState({ ...newHistoryItem, petani: farmer?.nama || user?.nama || 'Budi Santoso' });
      setPembukaanStep('success');
      fetchData();

      toast.success(
        `PUPUK BERHASIL DIBUKA! ${scannedBag.jenisPupuk} ${scannedBag.beratKg} kg sukses dicatat.`,
        { id: toastId, duration: 6000 }
      );
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal memproses pembukaan pupuk.', { id: toastId });
    } finally {
      setIsProcessingOpen(false);
    }
  };

  // Calculate Dynamic Quota & Usage
  const totalUreaUsed = historyList
    .filter((h) => h.jenis_pupuk?.toLowerCase().includes('urea'))
    .reduce((sum, h) => sum + (h.jumlah_kg || parseFloat(h.jumlah_pupuk) || 0), 0);

  const totalNpkUsed = historyList
    .filter((h) => h.jenis_pupuk?.toLowerCase().includes('npk'))
    .reduce((sum, h) => sum + (h.jumlah_kg || parseFloat(h.jumlah_pupuk) || 0), 0);

  const totalPupukDigunakan = totalUreaUsed + totalNpkUsed;

  const kuotaDisetujuiUrea = 500;
  const sisaKuotaUrea = Math.max(0, kuotaDisetujuiUrea - totalUreaUsed);

  const kuotaDisetujuiNpk = 400;
  const sisaKuotaNpk = Math.max(0, kuotaDisetujuiNpk - totalNpkUsed);

  // Form Handlers
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
      toast.error('Harap lengkapi semua kolom yang wajib diisi.');
      return;
    }

    const toastId = toast.loading('Mengirim pengajuan subsidi...');
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
      toast.success('Pengajuan subsidi pupuk berhasil dikirim! Berkas Anda masuk ke tahap Verifikasi.', { id: toastId, duration: 5000 });
      setActiveNav('status');
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal mengirim pengajuan.', { id: toastId });
    }
  };

  const handleCreateLand = async (e) => {
    e.preventDefault();
    if (!landFormData.lokasi_deskripsi || !landFormData.luas_m2 || !landFormData.alamat_lahan) {
      toast.error('Harap lengkapi data lahan.');
      return;
    }

    const toastId = toast.loading('Menyimpan data lahan baru...');
    try {
      await landsApi.create({
        lokasi_deskripsi: landFormData.lokasi_deskripsi,
        luas_m2: parseFloat(landFormData.luas_m2),
        alamat_lahan: landFormData.alamat_lahan,
        commodity_id: landFormData.commodity_id ? parseInt(landFormData.commodity_id) : (commodities[0]?.id || 1),
        status_kepemilikan: landFormData.status_kepemilikan,
        latitude: landFormData.latitude,
        longitude: landFormData.longitude,
        foto_lahan_url: landFormData.foto_lahan_url,
      });
      setShowAddLandModal(false);
      fetchData();
      toast.success('Lahan pertanian berhasil didaftarkan!', { id: toastId });
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal mendaftarkan lahan.', { id: toastId });
    }
  };

  const handleReviseSubmit = async (e) => {
    e.preventDefault();
    if (!selectedApp) return;

    const toastId = toast.loading('Mengunggah berkas perbaikan...');
    try {
      await applicationsApi.reviseDocs(selectedApp.id, {
        foto_ktp_url: reviseKtpUrl,
        foto_lahan_url: reviseLahanUrl,
      });
      setShowReviseModal(false);
      fetchData();
      toast.success('Perbaikan berkas berhasil diunggah! Status telah diperbarui ke Menunggu Verifikasi Berkas.', { id: toastId, duration: 5000 });
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal memperbarui berkas.', { id: toastId });
    }
  };

  const handleLogout = async () => {
    if (window.confirm('Apakah Anda yakin ingin keluar dari Portal Petani?')) {
      await logout();
      navigate('/login');
    }
  };

  // Nav items definition
  const USER_NAV_ITEMS = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'profil', label: 'Profil Saya', icon: User },
    { id: 'lahan', label: 'Data Lahan', icon: MapPin },
    { id: 'pengajuan', label: 'Pengajuan Subsidi', icon: PlusCircle },
    { id: 'status', label: 'Status Pengajuan', icon: Clock },
    { id: 'kuota', label: 'Kuota Pupuk', icon: PieChart },
    { id: 'pembukaan', label: 'Pembukaan Pupuk', icon: Camera, highlight: true },
    { id: 'riwayat', label: 'Riwayat Pembukaan', icon: History },
  ];

  if (loading) {
    return (
      <div className="space-y-8 pb-16 animate-pulse font-sans">
        <div className="rounded-3xl bg-emerald-100 h-36" />
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-28 bg-slate-200 rounded-2xl" />
          ))}
        </div>
        <div className="h-96 bg-slate-200 rounded-2xl" />
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-16 font-sans">
      {/* Top Banner Header */}
      <div className="rounded-3xl bg-gradient-to-r from-emerald-900 via-emerald-800 to-green-900 text-white p-6 sm:p-8 relative overflow-hidden shadow-xl border border-emerald-700/50">
        <div className="absolute right-0 top-0 bottom-0 w-1/3 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-green-400/20 via-transparent to-transparent pointer-events-none" />
        
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <div className="flex items-center gap-2 text-emerald-300 text-xs font-bold uppercase tracking-wider mb-2">
              <Sparkles className="w-4 h-4" /> Portal Petani & Kelompok Tani Kabupaten Mojokerto
            </div>
            <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
              Selamat Datang, {farmer?.nama || user?.nama || 'Budi Santoso'}!
            </h1>
            <p className="mt-1 text-xs sm:text-sm text-emerald-100 max-w-2xl leading-relaxed">
              Sistem resmi verifikasi subsidi, pemantauan kuota, dan pemindaian QR Code pada karung pupuk fisik berbasis GPS geofencing.
            </p>
          </div>

        </div>
      </div>

      {/* Main Navigation Bar for User / Petani */}
      <div className="bg-white rounded-2xl p-2 border border-slate-200 shadow-xs flex items-center justify-between gap-2 overflow-x-auto scrollbar-none">
        <div className="flex items-center gap-1.5 min-w-max">
          {USER_NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            const isActive = activeNav === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveNav(item.id)}
                className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  isActive
                    ? 'bg-emerald-600 text-white shadow-sm shadow-emerald-600/30'
                    : item.highlight
                    ? 'bg-emerald-50 text-emerald-800 hover:bg-emerald-100 border border-emerald-200'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <Icon className={`w-4 h-4 ${isActive ? 'text-white' : item.highlight ? 'text-emerald-600' : 'text-slate-400'}`} />
                <span>{item.label}</span>
                {item.highlight && !isActive && (
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                )}
              </button>
            );
          })}
        </div>

        <button
          onClick={handleLogout}
          className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold text-rose-600 hover:bg-rose-50 hover:text-rose-700 transition-colors ml-auto shrink-0 cursor-pointer"
          title="Keluar dari akun"
        >
          <LogOut className="w-4 h-4" />
          <span className="hidden sm:inline">Logout</span>
        </button>
      </div>

      {/* ========================================================================= */}
      {/* 1. DASHBOARD VIEW (RINGKASAN & KPI CARDS)                                 */}
      {/* ========================================================================= */}
      {activeNav === 'dashboard' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          {/* KPI Cards Ringkasan */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
            <KPICard
              title="Sisa Kuota Urea"
              value={`${sisaKuotaUrea} kg`}
              subtitle={`Dari total kuota ${kuotaDisetujuiUrea} kg`}
              icon={Tractor}
              color="emerald"
              badge="Subsidi"
            />
            <KPICard
              title="Sisa Kuota NPK"
              value={`${sisaKuotaNpk} kg`}
              subtitle={`Dari total kuota ${kuotaDisetujuiNpk} kg`}
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
              title="Total Pupuk Sudah Digunakan"
              value={`${totalPupukDigunakan} kg`}
              subtitle="Divalidasi GPS di Lahan"
              icon={PackageCheck}
              color="purple"
              badge="Tervalidasi"
            />
          </div>

          {/* Quick Shortcuts Banner for Scan QR Karung Pupuk */}
          <div className="rounded-2xl border border-emerald-200 bg-gradient-to-r from-emerald-50 to-green-50 p-5 flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-3.5">
              <div className="w-12 h-12 rounded-xl bg-emerald-600 text-white flex items-center justify-center shrink-0 shadow-md shadow-emerald-600/20">
                <Camera className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-900">
                  Akan Menggunakan Pupuk Subsidi di Lahan?
                </h3>
                <p className="text-xs text-slate-600 mt-0.5">
                  Gunakan kamera ponsel untuk memindai QR Code yang tercetak pada karung pupuk fisik sebelum dibuka.
                </p>
              </div>
            </div>
            <button
              onClick={() => {
                setActiveNav('pembukaan');
                setIsScannerActive(true);
              }}
              className="px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-md shadow-emerald-600/20 flex items-center gap-2 shrink-0 cursor-pointer"
            >
              <span>Scan QR Karung Pupuk</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>

          {/* 2-Column: Ringkasan Kuota & Profil Ringkas */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Quick Profile Summary */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                  <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                    <ShieldCheck className="w-4 h-4 text-emerald-600" />
                    Profil Petani
                  </h2>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                    ✓ Data Terverifikasi
                  </span>
                </div>

                <div className="mt-4 space-y-3 text-xs">
                  <div>
                    <span className="text-slate-400 block text-[11px]">Nama Lengkap</span>
                    <span className="font-bold text-slate-900 text-sm">{farmer?.nama || user?.nama || 'Budi Santoso'}</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px]">NIK</span>
                    <span className="font-mono font-bold text-slate-800">{farmer?.nik || '3516012345670001'}</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px]">Kelompok Tani (Poktan)</span>
                    <span className="font-semibold text-slate-800">{farmer?.farmer_group?.nama_kelompok || 'Poktan Sumber Makmur'}</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px]">Nomor HP / WhatsApp</span>
                    <span className="font-semibold text-slate-800">{farmer?.kontak || '0812-3456-7890'}</span>
                  </div>
                </div>
              </div>

              <button
                onClick={() => setActiveNav('profil')}
                className="mt-5 w-full py-2.5 rounded-xl border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-bold transition-colors flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <span>Lihat Profil Selengkapnya</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </button>
            </div>

            {/* Quick Kuota Summary */}
            <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-5">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                  <PieChart className="w-4 h-4 text-emerald-600" />
                  Ringkasan Kuota Pupuk Saya (Musim Tanam 2026)
                </h2>
                <button
                  onClick={() => setActiveNav('kuota')}
                  className="text-xs text-emerald-600 hover:text-emerald-700 font-bold flex items-center gap-1"
                >
                  Detail Kuota <ChevronRight className="w-3.5 h-3.5" />
                </button>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Urea Progress */}
                <div className="p-4 rounded-xl border border-slate-200 bg-slate-50/50 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-900">UREA BERSUBSIDI</span>
                    <span className="text-[11px] font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded">
                      Sisa {sisaKuotaUrea} kg
                    </span>
                  </div>
                  <div className="space-y-1 text-xs text-slate-600">
                    <div className="flex justify-between">
                      <span>Kuota Disetujui:</span>
                      <strong className="text-slate-800">{kuotaDisetujuiUrea} kg</strong>
                    </div>
                    <div className="flex justify-between">
                      <span>Sudah Digunakan:</span>
                      <strong className="text-purple-700">{totalUreaUsed} kg</strong>
                    </div>
                  </div>
                  {/* Progress Bar */}
                  <div className="w-full bg-slate-200 h-2.5 rounded-full overflow-hidden">
                    <div
                      className="bg-emerald-600 h-full rounded-full transition-all duration-500"
                      style={{ width: `${Math.min(100, (totalUreaUsed / kuotaDisetujuiUrea) * 100)}%` }}
                    />
                  </div>
                  <p className="text-[10px] text-slate-400 text-right">
                    {Math.round((totalUreaUsed / kuotaDisetujuiUrea) * 100)}% kuota terpakai
                  </p>
                </div>

                {/* NPK Progress */}
                <div className="p-4 rounded-xl border border-slate-200 bg-slate-50/50 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-900">NPK PHONSKA</span>
                    <span className="text-[11px] font-bold text-blue-700 bg-blue-100 px-2 py-0.5 rounded">
                      Sisa {sisaKuotaNpk} kg
                    </span>
                  </div>
                  <div className="space-y-1 text-xs text-slate-600">
                    <div className="flex justify-between">
                      <span>Kuota Disetujui:</span>
                      <strong className="text-slate-800">{kuotaDisetujuiNpk} kg</strong>
                    </div>
                    <div className="flex justify-between">
                      <span>Sudah Digunakan:</span>
                      <strong className="text-purple-700">{totalNpkUsed} kg</strong>
                    </div>
                  </div>
                  {/* Progress Bar */}
                  <div className="w-full bg-slate-200 h-2.5 rounded-full overflow-hidden">
                    <div
                      className="bg-blue-600 h-full rounded-full transition-all duration-500"
                      style={{ width: `${Math.min(100, (totalNpkUsed / kuotaDisetujuiNpk) * 100)}%` }}
                    />
                  </div>
                  <p className="text-[10px] text-slate-400 text-right">
                    {Math.round((totalNpkUsed / kuotaDisetujuiNpk) * 100)}% kuota terpakai
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Applications Tracker */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div>
                <h2 className="text-sm font-bold text-slate-900">
                  Status Pengajuan Terkini
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Lacak perkembangan verifikasi dokumen dan penugasan survei lahan
                </p>
              </div>
              <button
                onClick={() => setActiveNav('status')}
                className="text-xs text-emerald-600 hover:text-emerald-700 font-bold flex items-center gap-1"
              >
                Lihat Semua Pengajuan <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {applications.slice(0, 2).map((app) => (
              <div key={app.id} className="p-4 rounded-xl border border-slate-200 bg-slate-50/50 space-y-3">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div>
                    <span className="text-xs font-mono font-bold text-slate-400 mr-2">#{app.id}</span>
                    <strong className="text-sm font-bold text-slate-900">
                      Pupuk {app.fertilizer?.nama_pupuk} — {app.jumlah_diajukan} kg
                    </strong>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Lahan: {app.land?.lokasi_deskripsi || 'Sawah Petani'}
                    </p>
                  </div>
                  <StatusBadge status={app.status} />
                </div>
                <div className="bg-white p-3 rounded-lg border border-slate-100">
                  <ProgressStepper status={app.status} />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 2. PROFIL PETANI                                                          */}
      {/* ========================================================================= */}
      {activeNav === 'profil' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-6">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div>
                <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                  <User className="w-5 h-5 text-emerald-600" />
                  Profil Petani Terdaftar
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Informasi data kependudukan dan status keanggotaan kelompok tani resmi
                </p>
              </div>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800 border border-emerald-300">
                <CheckCircle2 className="w-3.5 h-3.5" /> Data Terverifikasi
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Photo KTP Card */}
              <div className="space-y-3">
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider">
                  Foto KTP Terdaftar
                </label>
                <div 
                  onClick={() => setViewerPhoto({
                    isOpen: true,
                    title: `Foto KTP: ${farmer?.nama || user?.nama || 'Petani'}`,
                    url: farmer?.foto_ktp_url || '/files/ktp/sample_ktp1.jpg',
                    description: `NIK: ${farmer?.nik || '3516012345670001'} | Status: Data Terverifikasi`
                  })}
                  className="relative rounded-2xl overflow-hidden border border-slate-200 bg-slate-100 aspect-16/10 group cursor-pointer shadow-xs flex items-center justify-center"
                >
                  <img 
                    src={farmer?.foto_ktp_url || '/files/ktp/sample_ktp1.jpg'} 
                    alt="Foto KTP" 
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-1.5 text-white text-xs font-bold backdrop-blur-xs">
                    <Eye className="w-4 h-4" /> Klik untuk Perbesar KTP
                  </div>
                </div>
                <p className="text-[11px] text-slate-400 text-center">
                  Klik foto KTP untuk memeriksa data ukuran penuh
                </p>
              </div>

              {/* Farmer Details */}
              <div className="md:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Nama Lengkap</span>
                  <strong className="text-slate-900 text-sm mt-0.5 block">{farmer?.nama || user?.nama || 'Budi Santoso'}</strong>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Nomor Induk Kependudukan (NIK)</span>
                  <strong className="font-mono text-slate-900 text-sm mt-0.5 block">{farmer?.nik || '3516012345670001'}</strong>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Nomor HP / WhatsApp</span>
                  <strong className="text-slate-900 text-sm mt-0.5 block">{farmer?.kontak || '0812-3456-7890'}</strong>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Alamat Email</span>
                  <strong className="text-slate-900 text-sm mt-0.5 block">{user?.email || 'budi.santoso@pertanian.id'}</strong>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Kelompok Tani (Poktan)</span>
                  <strong className="text-slate-900 text-sm mt-0.5 block">{farmer?.farmer_group?.nama_kelompok || 'Poktan Sumber Makmur'}</strong>
                  <span className="text-[10px] text-emerald-700 font-semibold">Wilayah: {farmer?.farmer_group?.wilayah || 'Kec. Bangsal, Mojokerto'}</span>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Status Verifikasi Akun</span>
                  <span className="inline-flex items-center gap-1 text-emerald-700 font-bold text-xs mt-1">
                    <CheckCircle2 className="w-4 h-4" /> ✓ Data Terverifikasi Dinas
                  </span>
                </div>

                <div className="sm:col-span-2 p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Alamat Domisili KTP</span>
                  <p className="font-medium text-slate-800 leading-relaxed mt-0.5">
                    {farmer?.alamat || 'Dusun Kebondalem RT 02 / RW 03, Desa Kebondalem, Kecamatan Mojosari, Kabupaten Mojokerto, Jawa Timur 61382'}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 3. DATA LAHAN                                                             */}
      {/* ========================================================================= */}
      {activeNav === 'lahan' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
              <div>
                <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                  <MapPin className="w-5 h-5 text-emerald-600" />
                  Daftar Lahan Pertanian Milik / Sewa ({lands.length})
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Lahan terdaftar yang berhak mendapatkan kuota pupuk bersubsidi
                </p>
              </div>
              <button
                onClick={() => setShowAddLandModal(true)}
                className="px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-2 shadow-sm shadow-emerald-200 cursor-pointer self-start sm:self-auto"
              >
                <Plus className="w-4 h-4" />
                <span>Tambah Lahan</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {lands.map((land) => (
                <div
                  key={land.id}
                  className="rounded-2xl border border-slate-200 overflow-hidden bg-white hover:border-slate-300 hover:shadow-md transition-all flex flex-col justify-between"
                >
                  {/* Photo Lahan */}
                  <div
                    onClick={() => setViewerPhoto({
                      isOpen: true,
                      title: `Foto Lahan: ${land.lokasi_deskripsi || 'Lahan Pertanian'}`,
                      url: land.foto_lahan_url || '/files/lahan/sample_lahan1.jpg',
                      description: `Luas: ${land.luas_m2} m² | Alamat: ${land.alamat_lahan}`
                    })}
                    className="relative aspect-16/10 bg-slate-100 overflow-hidden group cursor-pointer"
                  >
                    <img
                      src={land.foto_lahan_url || '/files/lahan/sample_lahan1.jpg'}
                      alt={land.lokasi_deskripsi}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                    <div className="absolute top-2 left-2 px-2.5 py-0.5 rounded-full bg-black/60 text-white text-[10px] font-bold backdrop-blur-xs">
                      {land.commodity?.nama_komoditas || 'Padi'}
                    </div>
                    <div className="absolute top-2 right-2 px-2.5 py-0.5 rounded-full bg-emerald-600 text-white text-[10px] font-bold shadow-xs">
                      ✓ Terverifikasi
                    </div>
                    <div className="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-xs font-bold gap-1">
                      <Eye className="w-4 h-4" /> Lihat Foto
                    </div>
                  </div>

                  {/* Details */}
                  <div className="p-4 flex-1 flex flex-col justify-between space-y-3 text-xs">
                    <div>
                      <h4 className="font-bold text-slate-900 text-sm">
                        {land.lokasi_deskripsi || 'Sawah Blok Timur Kebondalem'}
                      </h4>
                      <div className="mt-2 space-y-1 text-slate-600">
                        <div className="flex justify-between">
                          <span className="text-slate-400">Luas Lahan:</span>
                          <strong className="text-slate-800">{Number(land.luas_m2).toLocaleString('id-ID')} m²</strong>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Komoditas:</span>
                          <span className="font-semibold text-emerald-700">{land.commodity?.nama_komoditas || 'Padi'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Status Lahan:</span>
                          <span className="font-medium text-slate-700">{land.status_kepemilikan || 'MILIK'}</span>
                        </div>
                      </div>

                      <p className="mt-2 text-slate-500 text-[11px] flex items-start gap-1">
                        <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0 mt-0.5" />
                        <span className="line-clamp-2">{land.alamat_lahan}</span>
                      </p>
                    </div>

                    <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                      <span className="font-mono text-[11px] text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                        {formatCoord(land.latitude)}, {formatCoord(land.longitude)}
                      </span>
                      <button
                        onClick={() => setSelectedLandDetail(land)}
                        className="px-3 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs transition-colors cursor-pointer"
                      >
                        Lihat Detail
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 4. PENGAJUAN SUBSIDI PUPUK                                                */}
      {/* ========================================================================= */}
      {activeNav === 'pengajuan' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-6">
            <div className="pb-4 border-b border-slate-100">
              <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <PlusCircle className="w-5 h-5 text-emerald-600" />
                Form Pengajuan Subsidi Pupuk
              </h2>
              <p className="text-xs text-slate-500 mt-0.5">
                Isi formulir untuk mengajukan alokasi pupuk bersubsidi musim tanam. Pengajuan akan melalui verifikasi berkas dan survei fisik lapangan.
              </p>
            </div>

            <form onSubmit={handleCreateApplication} className="space-y-5 max-w-3xl">
              {/* Select Land */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  Pilih Lahan Pertanian <span className="text-rose-500">*</span>
                </label>
                <select
                  value={formData.land_id}
                  onChange={handleLandSelectChange}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  required
                >
                  <option value="">-- Pilih Lahan Terdaftar --</option>
                  {lands.map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.lokasi_deskripsi || 'Lahan Sawah'} — {l.luas_m2} m² ({l.commodity?.nama_komoditas || 'Padi'})
                    </option>
                  ))}
                </select>
              </div>

              {/* Fertilizer & Amount Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">
                    Jenis Pupuk Bersubsidi <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={formData.fertilizer_id}
                    onChange={(e) => setFormData({ ...formData, fertilizer_id: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                    required
                  >
                    <option value="">-- Pilih Pupuk --</option>
                    {fertilizers.map((f) => (
                      <option key={f.id} value={f.id}>
                        {f.nama_pupuk} (Satuan: {f.satuan})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">
                    Jumlah yang Diajukan (kg) <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="number"
                    min="10"
                    max="1000"
                    step="5"
                    placeholder="Contoh: 100"
                    value={formData.jumlah_diajukan}
                    onChange={(e) => setFormData({ ...formData, jumlah_diajukan: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden font-bold"
                    required
                  />
                </div>
              </div>

              {/* Address */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  Alamat Lokasi Lahan <span className="text-rose-500">*</span>
                </label>
                <textarea
                  rows={2}
                  value={formData.alamat_lahan}
                  onChange={(e) => setFormData({ ...formData, alamat_lahan: e.target.value })}
                  placeholder="Nama dusun, RT/RW, desa, kecamatan"
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  required
                />
              </div>

              {/* Map Coordinates Picker */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  Titik Koordinat GPS Lahan (Geser pin pada peta)
                </label>
                <MapPicker
                  latitude={formData.latitude}
                  longitude={formData.longitude}
                  onChange={(lat, lng) => setFormData({ ...formData, latitude: lat, longitude: lng })}
                />
                <div className="mt-2 flex items-center justify-between text-xs text-slate-500">
                  <span>Latitude: <strong className="font-mono text-slate-800">{formatCoord(formData.latitude)}</strong></span>
                  <span>Longitude: <strong className="font-mono text-slate-800">{formatCoord(formData.longitude)}</strong></span>
                </div>
              </div>

              {/* Actions */}
              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setActiveNav('dashboard')}
                  className="px-5 py-2.5 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="px-6 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-md shadow-emerald-200 transition-colors cursor-pointer"
                >
                  Kirim Pengajuan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 5. STATUS / PROGRESS PENGAJUAN                                            */}
      {/* ========================================================================= */}
      {activeNav === 'status' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
              <div>
                <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                  <Clock className="w-5 h-5 text-emerald-600" />
                  Status & Progres Pengajuan Pupuk ({applications.length})
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Tahapan: 1. Pengajuan → 2. Verifikasi Berkas → 3. Penugasan PPL → 4. Survei Lapangan → 5. Persetujuan Admin → 6. Penggunaan Pupuk
                </p>
              </div>
              <button
                onClick={() => setShowApplyModal(true)}
                className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-sm shadow-emerald-200 cursor-pointer shrink-0"
              >
                <Plus className="w-4 h-4" />
                <span>Ajukan Baru</span>
              </button>
            </div>

            {applications.length === 0 ? (
              <div className="py-12 text-center">
                <Tractor className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                <p className="text-sm font-bold text-slate-700">Belum Ada Pengajuan Subsidi</p>
                <p className="text-xs text-slate-400 mt-1">
                  Klik tombol "+ Ajukan Baru" untuk mengajukan kuota pupuk.
                </p>
              </div>
            ) : (
              <div className="space-y-6">
                {applications.map((app) => {
                  const isNeedsRevision = app.status === 'PERLU_PERBAIKAN_BERKAS' || app.status === 'DITOLAK_BERKAS';
                  const isApproved = app.status === 'DISETUJUI' || app.status === 'DIJADWALKAN_DISTRIBUSI';
                  const isUsed = app.status === 'TERSALURKAN';

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
                              Diajukan:{' '}
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

                          {/* Revisi Berkas Action */}
                          {isNeedsRevision && (
                            <button
                              onClick={() => {
                                setSelectedApp(app);
                                setShowReviseModal(true);
                              }}
                              className="px-3.5 py-1.5 rounded-lg bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-sm animate-pulse cursor-pointer"
                            >
                              <AlertTriangle className="w-3.5 h-3.5" /> Revisi Berkas
                            </button>
                          )}

                          {/* Shortcut to Scan QR Karung Pupuk */}
                          {isApproved && (
                            <button
                              onClick={() => {
                                setActiveNav('pembukaan');
                                setIsScannerActive(true);
                              }}
                              className="px-3.5 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-sm shadow-emerald-200 cursor-pointer"
                            >
                              <Camera className="w-3.5 h-3.5" /> Scan QR Karung
                            </button>
                          )}

                          {isUsed && (
                            <span className="px-3 py-1 rounded-lg bg-purple-100 text-purple-800 font-bold text-xs flex items-center gap-1 font-mono">
                              <Check className="w-3.5 h-3.5" /> Terpakai
                            </span>
                          )}
                        </div>
                      </div>

                      {/* 6-Stage Progress Stepper */}
                      <div className="bg-slate-50/70 rounded-xl p-3 sm:p-4 border border-slate-100">
                        <ProgressStepper status={app.status} />
                      </div>

                      {/* Admin Notes */}
                      {app.catatan_admin_berkas && (
                        <div className="text-xs p-3 rounded-xl bg-amber-50 border border-amber-200 text-amber-900 flex items-start gap-2">
                          <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                          <div>
                            <strong className="font-bold">Catatan Verifikasi Admin: </strong>
                            <span>{app.catatan_admin_berkas}</span>
                          </div>
                        </div>
                      )}

                      {/* PPL Survey Notes */}
                      {app.survey && (
                        <div className="text-xs p-3 rounded-xl bg-blue-50 border border-blue-200 text-blue-900 flex items-start justify-between gap-3">
                          <div>
                            <strong className="font-bold">Hasil Survei Petugas PPL: </strong>
                            <p className="mt-0.5">
                              Kondisi Lahan: <span className="font-semibold">{app.survey.kondisi_fisik_lahan}</span> | 
                              Tanaman: <span className="font-semibold">{app.survey.kondisi_tanaman}</span> | 
                              Rekomendasi: <span className="font-bold text-emerald-700">{app.survey.rekomendasi}</span>
                            </p>
                          </div>
                          {app.survey.foto_survei_urls?.[0] && (
                            <button
                              type="button"
                              onClick={() => setViewerPhoto({
                                isOpen: true,
                                title: `Foto Survei Lapangan PPL (#${app.id})`,
                                url: app.survey.foto_survei_urls[0],
                                description: 'Hasil pemeriksaan fisik langsung di sawah oleh Petugas PPL'
                              })}
                              className="px-2 py-1 rounded bg-blue-100 hover:bg-blue-200 text-blue-800 text-[11px] font-bold shrink-0 cursor-pointer"
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
        </div>
      )}

      {/* ========================================================================= */}
      {/* 6. KUOTA PUPUK SAYA                                                       */}
      {/* ========================================================================= */}
      {activeNav === 'kuota' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-6">
            <div className="pb-4 border-b border-slate-100">
              <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <PieChart className="w-5 h-5 text-emerald-600" />
                Kuota Pupuk Saya (Tahun Anggaran 2026)
              </h2>
              <p className="text-xs text-slate-500 mt-0.5">
                Pantau kuota alokasi resmi dari RDKK Dinas Pertanian Kabupaten Mojokerto dan rincian penggunaan di lahan
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* UREA Card */}
              <div className="rounded-2xl border border-slate-200 p-6 bg-gradient-to-br from-white to-emerald-50/30 shadow-xs space-y-5">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center font-bold text-sm">
                      Ur
                    </div>
                    <div>
                      <h3 className="text-base font-black text-slate-900">UREA BERSUBSIDI</h3>
                      <p className="text-xs text-slate-500">Pupuk Tunggal Nitrogen</p>
                    </div>
                  </div>
                  <span className="text-xs font-bold px-3 py-1 rounded-full bg-emerald-100 text-emerald-800">
                    Alokasi Musim Tanam
                  </span>
                </div>

                <div className="p-4 rounded-xl bg-white border border-slate-200/80 space-y-2.5 text-xs">
                  <div className="flex justify-between items-center">
                    <span className="text-slate-500">Kuota Disetujui:</span>
                    <strong className="text-slate-900 text-sm">{kuotaDisetujuiUrea} kg</strong>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-slate-500">Sudah Digunakan:</span>
                    <strong className="text-purple-700 text-sm">{totalUreaUsed} kg</strong>
                  </div>
                  <div className="pt-2 border-t border-slate-100 flex justify-between items-center">
                    <span className="text-slate-700 font-bold">Sisa Kuota:</span>
                    <strong className="text-emerald-700 text-base">{sisaKuotaUrea} kg</strong>
                  </div>
                </div>

                {/* Progress Bar */}
                <div className="space-y-1.5">
                  <div className="flex justify-between text-xs text-slate-500">
                    <span>Kemajuan Penggunaan</span>
                    <span className="font-bold text-slate-700">{Math.round((totalUreaUsed / kuotaDisetujuiUrea) * 100)}%</span>
                  </div>
                  <div className="w-full bg-slate-200 h-3 rounded-full overflow-hidden">
                    <div
                      className="bg-emerald-600 h-full rounded-full transition-all duration-500"
                      style={{ width: `${Math.min(100, (totalUreaUsed / kuotaDisetujuiUrea) * 100)}%` }}
                    />
                  </div>
                </div>
              </div>

              {/* NPK PHONSKA Card */}
              <div className="rounded-2xl border border-slate-200 p-6 bg-gradient-to-br from-white to-blue-50/30 shadow-xs space-y-5">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-blue-600 text-white flex items-center justify-center font-bold text-sm">
                      NPK
                    </div>
                    <div>
                      <h3 className="text-base font-black text-slate-900">NPK PHONSKA</h3>
                      <p className="text-xs text-slate-500">Pupuk Majemuk N-P-K</p>
                    </div>
                  </div>
                  <span className="text-xs font-bold px-3 py-1 rounded-full bg-blue-100 text-blue-800">
                    Alokasi Musim Tanam
                  </span>
                </div>

                <div className="p-4 rounded-xl bg-white border border-slate-200/80 space-y-2.5 text-xs">
                  <div className="flex justify-between items-center">
                    <span className="text-slate-500">Kuota Disetujui:</span>
                    <strong className="text-slate-900 text-sm">{kuotaDisetujuiNpk} kg</strong>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-slate-500">Sudah Digunakan:</span>
                    <strong className="text-purple-700 text-sm">{totalNpkUsed} kg</strong>
                  </div>
                  <div className="pt-2 border-t border-slate-100 flex justify-between items-center">
                    <span className="text-slate-700 font-bold">Sisa Kuota:</span>
                    <strong className="text-blue-700 text-base">{sisaKuotaNpk} kg</strong>
                  </div>
                </div>

                {/* Progress Bar */}
                <div className="space-y-1.5">
                  <div className="flex justify-between text-xs text-slate-500">
                    <span>Kemajuan Penggunaan</span>
                    <span className="font-bold text-slate-700">{Math.round((totalNpkUsed / kuotaDisetujuiNpk) * 100)}%</span>
                  </div>
                  <div className="w-full bg-slate-200 h-3 rounded-full overflow-hidden">
                    <div
                      className="bg-blue-600 h-full rounded-full transition-all duration-500"
                      style={{ width: `${Math.min(100, (totalNpkUsed / kuotaDisetujuiNpk) * 100)}%` }}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 7 & 8. PEMBUKAAN PUPUK — SCANNER CAMERA & GEOFENCING VALIDATION            */}
      {/* ========================================================================= */}
      {activeNav === 'pembukaan' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
            
            {/* Top Breadcrumb & Step Navigation */}
            <div className="border-b border-slate-100 p-4 sm:p-6 bg-slate-50/50">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <h2 className="text-xl font-black text-slate-900 font-display uppercase tracking-tight flex items-center gap-2">
                    <Camera className="w-5 h-5 text-emerald-600" />
                    Pembukaan Pupuk
                  </h2>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Scan QR Code pada karung pupuk untuk melakukan validasi pembukaan di lahan.
                  </p>
                </div>

                {/* Reset / Step status */}
                {pembukaanStep !== 'select' && pembukaanStep !== 'success' && (
                  <button
                    onClick={resetPembukaanFlow}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-600 hover:text-rose-600 hover:border-rose-200 bg-white transition-all cursor-pointer self-start sm:self-auto shadow-xs"
                  >
                    <RefreshCw className="w-3.5 h-3.5" />
                    <span>Ganti Alokasi / Mulai Ulang</span>
                  </button>
                )}
              </div>

              {/* Visual Steps Ribbon (1 -> 2 -> 3 -> 4) */}
              <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-2 text-center text-xs font-bold">
                <div className={`p-2.5 rounded-xl border transition-all ${
                  pembukaanStep === 'select' 
                    ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs' 
                    : ['gps', 'scan', 'result', 'success'].includes(pembukaanStep)
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                      : 'bg-white text-slate-400 border-slate-200'
                }`}>
                  1. Pilih Alokasi
                </div>
                <div className={`p-2.5 rounded-xl border transition-all ${
                  pembukaanStep === 'gps' 
                    ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs' 
                    : ['scan', 'result', 'success'].includes(pembukaanStep)
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                      : 'bg-white text-slate-400 border-slate-200'
                }`}>
                  2. Validasi GPS
                </div>
                <div className={`p-2.5 rounded-xl border transition-all ${
                  pembukaanStep === 'scan' 
                    ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs' 
                    : ['result', 'success'].includes(pembukaanStep)
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                      : 'bg-white text-slate-400 border-slate-200'
                }`}>
                  3. Scan QR Karung
                </div>
                <div className={`p-2.5 rounded-xl border transition-all ${
                  ['result', 'success'].includes(pembukaanStep)
                    ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs' 
                    : 'bg-white text-slate-400 border-slate-200'
                }`}>
                  4. Validasi & Sukses
                </div>
              </div>
            </div>

            <div className="p-6 sm:p-8">
              {/* ============================================================ */}
              {/* STEP 1: PILIH ALOKASI PUPUK                                  */}
              {/* ============================================================ */}
              {pembukaanStep === 'select' && (
                <div className="space-y-6">
                  <div className="p-4 rounded-2xl bg-emerald-50/80 border border-emerald-200/80 text-emerald-950 flex items-start gap-3">
                    <Sparkles className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
                    <div className="text-xs leading-relaxed">
                      <strong className="block font-bold mb-0.5">Langkah 1: Pilih Alokasi Pupuk</strong>
                      Pilih kuota pupuk subsidi milik Anda yang hendak dibuka di petak sawah. Setelah dipilih, sistem akan meminta verifikasi lokasi GPS sebelum membuka kamera untuk scan QR pada karung pupuk.
                    </div>
                  </div>

                  <div className="space-y-3">
                    <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                      Daftar Alokasi Pupuk Siap Digunakan:
                    </h3>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {MOCK_ALLOCATIONS.map((alloc) => (
                        <div
                          key={alloc.id}
                          className="p-5 rounded-2xl border-2 border-slate-200 hover:border-emerald-500 bg-white hover:bg-emerald-50/20 transition-all cursor-pointer shadow-xs hover:shadow-md flex flex-col justify-between gap-4 group"
                          onClick={() => {
                            setSelectedAllocation(alloc);
                            setPembukaanStep('gps');
                            toast.success(`Alokasi ${alloc.jenis_pupuk} (${alloc.jumlah_kg} kg) dipilih.`);
                          }}
                        >
                          <div className="space-y-3">
                            <div className="flex items-center justify-between gap-2">
                              <span className="text-xs font-mono font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded">
                                {alloc.id}
                              </span>
                              <span className="text-xs font-black px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 border border-emerald-200">
                                {alloc.status}
                              </span>
                            </div>

                            <div>
                              <h4 className="text-lg font-black text-slate-900 group-hover:text-emerald-700 transition-colors">
                                {alloc.jenis_pupuk} — {alloc.jumlah_kg} kg
                              </h4>
                              <p className="text-xs text-slate-600 flex items-center gap-1.5 mt-1">
                                <MapPin className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                                <span>Lahan: <strong>{alloc.nama_lahan}</strong></span>
                              </p>
                              <p className="text-[11px] text-slate-400 mt-0.5 pl-5">
                                {alloc.alamat_lahan}
                              </p>
                            </div>
                          </div>

                          <button
                            type="button"
                            className="w-full py-2.5 rounded-xl bg-emerald-600 group-hover:bg-emerald-700 text-white font-bold text-xs flex items-center justify-center gap-2 shadow-sm transition-all"
                          >
                            <span>Pilih Alokasi Ini</span>
                            <ArrowRight className="w-4 h-4" />
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* ============================================================ */}
              {/* STEP 2: VERIFIKASI GPS HP (GEOFENCING)                       */}
              {/* ============================================================ */}
              {pembukaanStep === 'gps' && selectedAllocation && (
                <div className="space-y-6">
                  {/* Active Allocation Bar */}
                  <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
                    <div>
                      <span className="text-slate-400 block text-[10px] uppercase font-bold">Alokasi Terpilih</span>
                      <strong className="text-slate-900 text-sm font-black">
                        {selectedAllocation.jenis_pupuk} — {selectedAllocation.jumlah_kg} kg
                      </strong>
                      <p className="text-slate-600 mt-0.5">
                        Lahan: <strong>{selectedAllocation.nama_lahan}</strong>
                      </p>
                    </div>
                    <button
                      onClick={() => setPembukaanStep('select')}
                      className="text-xs text-emerald-700 hover:text-emerald-800 font-bold self-start sm:self-auto underline cursor-pointer"
                    >
                      ← Ganti Alokasi
                    </button>
                  </div>

                  {/* GPS Verification Box */}
                  <div className="p-6 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-5">
                    <div className="flex items-center gap-3">
                      <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 ${
                        isLocationValid ? 'bg-emerald-100 text-emerald-700' : 'bg-rose-100 text-rose-700'
                      }`}>
                        <Navigation className="w-6 h-6 animate-pulse" />
                      </div>
                      <div>
                        <h3 className="text-base font-black text-slate-900">
                          Lokasi Anda sedang diverifikasi
                        </h3>
                        <p className="text-xs text-slate-500 mt-0.5">
                          GPS HP digunakan untuk memastikan petani benar-benar berada di sekitar titik lahan yang terdaftar.
                        </p>
                      </div>
                    </div>

                    {/* GPS Info Grid */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                      <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
                        <span className="text-slate-400 block text-[10px] font-bold uppercase">Titik Lahan Terdaftar</span>
                        <strong className="text-slate-900 block font-mono">
                          {formatCoord(activeAllocLat)}, {formatCoord(activeAllocLon)}
                        </strong>
                        <span className="text-[11px] text-slate-500 block">{selectedAllocation.nama_lahan}</span>
                      </div>

                      <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
                        <span className="text-slate-400 block text-[10px] font-bold uppercase">GPS HP Petani Real-Time</span>
                        <strong className="text-slate-900 block font-mono">
                          {currentGps.latitude}, {currentGps.longitude}
                        </strong>
                        <span className="text-[11px] text-slate-500 block">Akurasi ~{currentGps.accuracy}m</span>
                      </div>
                    </div>

                    <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between text-xs">
                      <span className="text-slate-600 font-medium">Jarak dari titik lahan terdaftar:</span>
                      <span className="font-mono font-black text-sm text-slate-900">{displayedDistance} meter</span>
                    </div>

                    {/* Geofencing Status Message */}
                    {isLocationValid ? (
                      <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-950 flex items-start gap-3">
                        <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
                        <div className="text-xs space-y-1">
                          <strong className="font-bold text-emerald-900">✓ Lokasi GPS Valid & Sesuai</strong>
                          <p className="text-emerald-800">
                            Anda terdeteksi berada di dalam radius lahan ({displayedDistance} meter). Silakan lanjutkan untuk memindai QR Code pada karung pupuk.
                          </p>
                        </div>
                      </div>
                    ) : (
                      <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-950 flex items-start gap-3">
                        <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
                        <div className="text-xs space-y-1">
                          <strong className="font-bold text-rose-900">Lokasi Tidak Sesuai</strong>
                          <p className="text-rose-800">
                            Anda berada di luar area lahan terdaftar ({displayedDistance} meter). Pembukaan pupuk hanya dapat dilakukan di area lahan yang telah diverifikasi.
                          </p>
                        </div>
                      </div>
                    )}

                    {/* Main Action Button */}
                    {isLocationValid ? (
                      <button
                        onClick={() => {
                          setPembukaanStep('scan');
                          setIsScannerActive(true);
                        }}
                        className="w-full py-4 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-black text-sm shadow-xl shadow-emerald-600/30 hover:scale-[1.01] transition-all flex items-center justify-center gap-2 cursor-pointer border border-emerald-500/40"
                      >
                        <Camera className="w-5 h-5" />
                        <span>[ SCAN QR PADA KARUNG PUPUK ]</span>
                      </button>
                    ) : (
                      <button
                        onClick={requestRealGps}
                        className="w-full py-3.5 rounded-2xl bg-rose-600 hover:bg-rose-700 text-white font-black text-sm shadow-lg shadow-rose-600/30 transition-all flex items-center justify-center gap-2 cursor-pointer"
                      >
                        <RefreshCw className="w-4 h-4" />
                        <span>[ Coba Lagi ]</span>
                      </button>
                    )}

                    {/* Simulation Bar */}
                    <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-2 text-xs">
                      <span className="text-slate-400 text-[11px] font-medium">Uji Coba Geofencing (Demo):</span>
                      <div className="flex items-center gap-2">
                        <button
                          type="button"
                          onClick={() => {
                            setIsSimulatedAtLand(true);
                            setSimulatedCustomDistance(18);
                            toast.success('Mode Simulasi: Di Sawah (18m)');
                          }}
                          className={`px-2.5 py-1 rounded-lg text-xs font-bold cursor-pointer ${
                            isSimulatedAtLand && simulatedCustomDistance === 18 ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-700'
                          }`}
                        >
                          ✓ Di Sawah (18m)
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setIsSimulatedAtLand(true);
                            setSimulatedCustomDistance(850);
                            toast.error('Mode Simulasi: Terlalu Jauh (850m)');
                          }}
                          className={`px-2.5 py-1 rounded-lg text-xs font-bold cursor-pointer ${
                            isSimulatedAtLand && simulatedCustomDistance === 850 ? 'bg-rose-600 text-white' : 'bg-slate-100 text-slate-700'
                          }`}
                        >
                          ✕ Luar Lahan (850m)
                        </button>
                        <button
                          type="button"
                          onClick={requestRealGps}
                          className={`px-2.5 py-1 rounded-lg text-xs font-bold cursor-pointer ${
                            !isSimulatedAtLand ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-700'
                          }`}
                        >
                          📡 GPS HP Asli
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* ============================================================ */}
              {/* STEP 3: SCAN QR PADA KARUNG PUPUK                            */}
              {/* ============================================================ */}
              {pembukaanStep === 'scan' && (
                <div className="bg-slate-900 rounded-3xl p-6 sm:p-8 text-white max-w-xl mx-auto space-y-6 border border-slate-800 shadow-2xl animate-in zoom-in-95 duration-200">
                  <div className="flex items-center justify-between border-b border-slate-800 pb-3">
                    <span className="text-xs font-bold uppercase tracking-wider text-emerald-400 flex items-center gap-2">
                      <Camera className="w-4 h-4" /> Pemindai QR Karung Pupuk Fisik
                    </span>
                    <button
                      onClick={() => setPembukaanStep('gps')}
                      className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors cursor-pointer"
                    >
                      <X className="w-5 h-5" />
                    </button>
                  </div>

                  {/* Viewfinder UI */}
                  <div className="relative rounded-2xl bg-black border-2 border-emerald-500/50 p-6 text-center space-y-4 overflow-hidden">
                    <div className="w-52 h-52 mx-auto border-4 border-dashed border-emerald-400 rounded-2xl flex flex-col items-center justify-center p-4 bg-emerald-950/20 relative animate-pulse">
                      <QrCode className="w-16 h-16 text-emerald-400 opacity-90" />
                      <span className="text-[11px] font-mono font-bold text-emerald-300 mt-2">KAMERA SCANNER HP</span>
                    </div>

                    <p className="text-xs text-slate-300 font-medium">
                      Arahkan kamera ke QR Code yang terdapat pada karung pupuk.
                    </p>

                    {/* Concept Workflow Indicator */}
                    <div className="p-2.5 rounded-xl bg-slate-950/80 border border-slate-800 text-[11px] text-slate-400 flex items-center justify-center gap-2">
                      <span>Karung pupuk</span>
                      <span>↓</span>
                      <span className="text-emerald-400 font-bold">[ QR CODE ]</span>
                      <span>↓</span>
                      <span>Petani scan pakai HP</span>
                    </div>

                    {/* Simulator buttons for laptop / demo testing */}
                    <div className="pt-4 border-t border-slate-800/80 space-y-3">
                      <p className="text-[11px] text-slate-400 font-semibold">
                        Simulasikan Pemindaian QR Karung Pupuk:
                      </p>
                      <div className="flex flex-wrap items-center justify-center gap-2">
                        <button
                          type="button"
                          onClick={() => handleScanBagId('EPU-000123')}
                          className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-mono font-bold text-xs cursor-pointer shadow-sm"
                        >
                          📷 Scan Karung Urea 70kg (EPU-000123)
                        </button>
                        <button
                          type="button"
                          onClick={() => handleScanBagId('EPU-000124')}
                          className="px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-white font-mono font-bold text-xs cursor-pointer shadow-sm"
                        >
                          📷 Scan Karung NPK 50kg (EPU-000124)
                        </button>
                        <button
                          type="button"
                          onClick={() => handleScanBagId('EPU-000099')}
                          className="px-3 py-1.5 rounded-lg bg-rose-600 hover:bg-rose-500 text-white font-mono font-bold text-xs cursor-pointer shadow-sm"
                        >
                          ⚠️ Scan QR Sudah Digunakan (EPU-000099)
                        </button>
                        <button
                          type="button"
                          onClick={() => handleScanBagId('EPU-INVALID')}
                          className="px-3 py-1.5 rounded-lg bg-slate-700 hover:bg-slate-600 text-white font-mono font-bold text-xs cursor-pointer shadow-sm"
                        >
                          ✕ Scan QR Tidak Valid
                        </button>
                      </div>

                      <div className="flex items-center gap-2 max-w-xs mx-auto pt-2">
                        <input
                          type="text"
                          placeholder="Ketik ID Karung (misal EPU-000123)"
                          value={manualInputId}
                          onChange={(e) => setManualInputId(e.target.value)}
                          className="flex-1 px-3 py-1.5 rounded-xl bg-slate-800 border border-slate-700 text-xs text-white font-mono uppercase focus:border-emerald-500 outline-hidden"
                        />
                        <button
                          type="button"
                          onClick={() => handleScanBagId(manualInputId || 'EPU-000123')}
                          className="px-3.5 py-1.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-900 font-bold text-xs cursor-pointer"
                        >
                          Pindai
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* ============================================================ */}
              {/* STEP 4: HASIL VALIDASI SETELAH SCAN                          */}
              {/* ============================================================ */}
              {pembukaanStep === 'result' && (
                <div className="max-w-2xl mx-auto space-y-6 animate-in fade-in duration-200">
                  <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                    <h3 className="text-base font-bold text-slate-900 flex items-center gap-2">
                      <ShieldCheck className="w-5 h-5 text-emerald-600" />
                      Hasil Validasi Pembukaan Pupuk
                    </h3>
                    <button
                      onClick={() => {
                        setQrValidation({ isScanned: false, isValidQr: false, isAlreadyUsed: false, isAllocationMatch: true, message: '' });
                        setScannedBag(null);
                        setPembukaanStep('scan');
                        setIsScannerActive(true);
                      }}
                      className="text-xs text-slate-500 hover:text-emerald-700 font-bold flex items-center gap-1 cursor-pointer"
                    >
                      <Camera className="w-3.5 h-3.5" /> [ Scan Ulang ]
                    </button>
                  </div>

                  {/* VALIDASI A: VALIDASI QR PUPUK */}
                  <div className={`p-5 rounded-2xl border transition-all ${
                    qrValidation.isValidQr 
                      ? 'bg-emerald-50/70 border-emerald-200 text-emerald-950'
                      : 'bg-rose-50/70 border-rose-200 text-rose-950'
                  }`}>
                    <div className="flex items-start gap-3">
                      {qrValidation.isValidQr ? (
                        <CheckCircle className="w-6 h-6 text-emerald-600 shrink-0 mt-0.5" />
                      ) : (
                        <XCircle className="w-6 h-6 text-rose-600 shrink-0 mt-0.5" />
                      )}
                      <div className="flex-1 space-y-2">
                        <div className="flex items-center justify-between">
                          <strong className="text-sm font-bold">A. VALIDASI QR PUPUK</strong>
                          <span className={`text-xs font-bold px-2.5 py-0.5 rounded-full ${
                            qrValidation.isValidQr ? 'bg-emerald-200 text-emerald-900' : 'bg-rose-200 text-rose-900'
                          }`}>
                            {qrValidation.isValidQr ? '✓ QR Pupuk Valid' : qrValidation.isAlreadyUsed ? '✕ QR Pupuk Sudah Digunakan' : '✕ QR Pupuk Tidak Valid'}
                          </span>
                        </div>

                        <p className="text-xs font-semibold">{qrValidation.message}</p>

                        {scannedBag ? (
                          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-2 text-xs">
                            <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                              <span className="text-slate-400 block text-[10px]">ID Pupuk</span>
                              <strong className="font-mono text-slate-900">{scannedBag.idPupuk}</strong>
                            </div>
                            <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                              <span className="text-slate-400 block text-[10px]">Jenis</span>
                              <strong className="text-slate-900">{scannedBag.jenisPupuk}</strong>
                            </div>
                            <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                              <span className="text-slate-400 block text-[10px]">Berat</span>
                              <strong className="text-slate-900">{scannedBag.beratKg} kg</strong>
                            </div>
                            <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                              <span className="text-slate-400 block text-[10px]">Status QR</span>
                              <strong className={qrValidation.isAlreadyUsed ? 'text-rose-600' : 'text-emerald-700'}>
                                {scannedBag.statusBag}
                              </strong>
                            </div>
                          </div>
                        ) : (
                          <div className="p-3 bg-white rounded-xl border border-rose-200 text-xs text-rose-800">
                            QR Code tidak terdaftar dalam sistem E-PUPUK.
                          </div>
                        )}

                        {qrValidation.isAlreadyUsed && scannedBag?.waktuDigunakan && (
                          <div className="p-2.5 rounded-xl bg-white border border-rose-200 text-xs text-rose-800 space-y-1">
                            <div>Waktu penggunaan sebelumnya: <strong>{scannedBag.waktuDigunakan}</strong></div>
                            <p className="text-[11px] text-rose-600">Jangan izinkan QR digunakan kembali.</p>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* VALIDASI B: VALIDASI ALOKASI */}
                  <div className={`p-5 rounded-2xl border transition-all ${
                    qrValidation.isValidQr && qrValidation.isAllocationMatch 
                      ? 'bg-emerald-50/70 border-emerald-200 text-emerald-950'
                      : 'bg-rose-50/70 border-rose-200 text-rose-950'
                  }`}>
                    <div className="flex items-start gap-3">
                      {qrValidation.isValidQr && qrValidation.isAllocationMatch ? (
                        <CheckCircle className="w-6 h-6 text-emerald-600 shrink-0 mt-0.5" />
                      ) : (
                        <XCircle className="w-6 h-6 text-rose-600 shrink-0 mt-0.5" />
                      )}
                      <div className="flex-1 space-y-2">
                        <div className="flex items-center justify-between">
                          <strong className="text-sm font-bold">B. VALIDASI ALOKASI</strong>
                          <span className={`text-xs font-bold px-2.5 py-0.5 rounded-full ${
                            qrValidation.isValidQr && qrValidation.isAllocationMatch ? 'bg-emerald-200 text-emerald-900' : 'bg-rose-200 text-rose-900'
                          }`}>
                            {qrValidation.isValidQr && qrValidation.isAllocationMatch ? '✓ Pupuk Sesuai Alokasi' : '✕ Alokasi Tidak Sesuai'}
                          </span>
                        </div>

                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Alokasi Petani:</span>
                            <strong className="text-slate-900">{farmer?.nama || user?.nama || 'Budi Santoso'}</strong>
                          </div>
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Jenis Alokasi:</span>
                            <strong className="text-slate-900">{selectedAllocation?.jenis_pupuk || 'Urea Bersubsidi'}</strong>
                          </div>
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Berat Alokasi:</span>
                            <strong className="text-slate-900">{selectedAllocation?.jumlah_kg || 70} kg</strong>
                          </div>
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Lahan Terdaftar:</span>
                            <strong className="text-slate-900">{selectedAllocation?.nama_lahan || targetLand.lokasi_deskripsi}</strong>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* VALIDASI C: VALIDASI GPS / GEOFENCING */}
                  <div className={`p-5 rounded-2xl border transition-all ${
                    isLocationValid 
                      ? 'bg-emerald-50/70 border-emerald-200 text-emerald-950'
                      : 'bg-rose-50/70 border-rose-200 text-rose-950'
                  }`}>
                    <div className="flex items-start gap-3">
                      {isLocationValid ? (
                        <CheckCircle className="w-6 h-6 text-emerald-600 shrink-0 mt-0.5" />
                      ) : (
                        <XCircle className="w-6 h-6 text-rose-600 shrink-0 mt-0.5" />
                      )}
                      <div className="flex-1 space-y-3">
                        <div className="flex items-center justify-between">
                          <strong className="text-sm font-bold">C. VALIDASI GPS / GEOFENCING</strong>
                          <span className={`text-xs font-bold px-2.5 py-0.5 rounded-full ${
                            isLocationValid ? 'bg-emerald-200 text-emerald-900' : 'bg-rose-200 text-rose-900'
                          }`}>
                            {isLocationValid ? '✓ Lokasi Berada di Lahan' : '✕ Lokasi Tidak Sesuai'}
                          </span>
                        </div>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">GPS HP Petani:</span>
                            <strong className="font-mono text-slate-900">{currentGps.latitude}, {currentGps.longitude}</strong>
                          </div>
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Koordinat Lahan Terdaftar:</span>
                            <strong className="font-mono text-slate-900">{formatCoord(activeAllocLat)}, {formatCoord(activeAllocLon)}</strong>
                          </div>
                        </div>

                        <div className="flex justify-between items-center text-xs bg-white p-2.5 rounded-xl border border-slate-200">
                          <span className="text-slate-600">Jarak dari Titik Lahan Sawah:</span>
                          <strong className="font-mono font-bold text-sm text-slate-900">{displayedDistance} meter</strong>
                        </div>

                        {isLocationValid ? (
                          <p className="text-xs font-semibold text-emerald-800">
                            ✓ Lahan Terverifikasi. Petani berada dalam radius lahan yang diperbolehkan ({displayedDistance}m).
                          </p>
                        ) : (
                          <div className="p-3 bg-white rounded-xl border border-rose-200 space-y-1 text-xs">
                            <strong className="text-rose-900 block font-bold">Lokasi Tidak Sesuai</strong>
                            <p className="text-rose-700">
                              Anda berada di luar area lahan terdaftar. Pembukaan pupuk hanya dapat dilakukan di area lahan yang telah diverifikasi.
                            </p>
                          </div>
                        )}

                        {/* Simulation Toggle in Result Card */}
                        <div className="pt-2 border-t border-slate-200/80 flex flex-wrap items-center justify-between gap-2 text-xs">
                          <span className="text-slate-500 font-medium">Uji Coba Geofencing (Demo):</span>
                          <div className="flex items-center gap-2">
                            <button
                              type="button"
                              onClick={() => {
                                setIsSimulatedAtLand(true);
                                setSimulatedCustomDistance(18);
                                toast.success('Mode Simulasi: Di Sawah (18m)');
                              }}
                              className={`px-2 py-1 rounded text-[11px] font-bold cursor-pointer ${
                                isSimulatedAtLand && simulatedCustomDistance === 18 ? 'bg-emerald-600 text-white' : 'bg-slate-200 text-slate-700'
                              }`}
                            >
                              ✓ Di Sawah (18m)
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                setIsSimulatedAtLand(true);
                                setSimulatedCustomDistance(850);
                                toast.error('Mode Simulasi: Terlalu Jauh (850m)');
                              }}
                              className={`px-2 py-1 rounded text-[11px] font-bold cursor-pointer ${
                                isSimulatedAtLand && simulatedCustomDistance === 850 ? 'bg-rose-600 text-white' : 'bg-slate-200 text-slate-700'
                              }`}
                            >
                              ✕ Terlalu Jauh (850m)
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* FINAL STATUS & CONFIRMATION BUTTON */}
                  {qrValidation.isValidQr && qrValidation.isAllocationMatch && isLocationValid ? (
                    <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-4">
                      <div className="pb-3 border-b border-slate-100 flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                          <span className="text-xs font-bold text-slate-900 uppercase">
                            Status: Pembukaan Pupuk Dapat Dilakukan
                          </span>
                        </div>
                        <span className="text-xs font-black px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                          SEMUA VALID
                        </span>
                      </div>

                      <div className="grid grid-cols-2 gap-2 text-xs text-slate-600 bg-slate-50 p-3 rounded-xl font-medium">
                        <div>✓ QR Pupuk Valid</div>
                        <div>✓ Pupuk Sesuai Alokasi</div>
                        <div>✓ Petani Terverifikasi</div>
                        <div>✓ Lokasi Berada di Lahan</div>
                      </div>

                      <button
                        onClick={handleConfirmPembukaanPupuk}
                        disabled={isProcessingOpen}
                        className="w-full py-4 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs shadow-lg shadow-emerald-600/30 transition-all flex items-center justify-center gap-2 cursor-pointer hover:scale-[1.01]"
                      >
                        <CheckCircle2 className="w-5 h-5" />
                        <span>[ KONFIRMASI PEMBUKAAN PUPUK ]</span>
                      </button>
                    </div>
                  ) : (
                    <div className="p-5 rounded-2xl bg-white border border-rose-200 shadow-xs space-y-3">
                      <div className="flex items-center gap-2 text-rose-700">
                        <XCircle className="w-5 h-5" />
                        <strong className="text-xs font-bold uppercase">Pembukaan Pupuk Ditolak / Belum Dapat Dilakukan</strong>
                      </div>
                      <p className="text-xs text-slate-600">
                        {!isLocationValid
                          ? 'Lokasi Anda berada di luar radius lahan yang terdaftar. Silakan menuju ke petak sawah yang sesuai lalu coba lagi.'
                          : qrValidation.isAlreadyUsed
                            ? 'QR karung ini telah tercatat pernah dibuka sebelumnya. Tidak dapat digunakan kembali.'
                            : !qrValidation.isValidQr
                              ? 'QR Code karung tidak terdaftar pada sistem E-PUPUK.'
                              : 'Jenis pupuk karung tidak sesuai dengan alokasi yang Anda pilih.'}
                      </p>

                      <div className="flex items-center gap-3 pt-2">
                        {!isLocationValid && (
                          <button
                            onClick={requestRealGps}
                            className="flex-1 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs cursor-pointer text-center"
                          >
                            [ Coba Lagi ]
                          </button>
                        )}
                        <button
                          onClick={() => {
                            setQrValidation({ isScanned: false, isValidQr: false, isAlreadyUsed: false, isAllocationMatch: true, message: '' });
                            setScannedBag(null);
                            setPembukaanStep('scan');
                            setIsScannerActive(true);
                          }}
                          className="flex-1 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold text-xs cursor-pointer text-center"
                        >
                          [ Scan Ulang ]
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* ============================================================ */}
              {/* STEP 5: PEMBUKAAN PUPUK BERHASIL (SUCCESS SCREEN)            */}
              {/* ============================================================ */}
              {pembukaanStep === 'success' && openSuccessState && (
                <div className="max-w-xl mx-auto space-y-6 animate-in zoom-in-95 duration-200">
                  <div className="text-center space-y-3 p-6 sm:p-8 rounded-3xl bg-gradient-to-b from-emerald-50 to-white border border-emerald-200 shadow-xl">
                    <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto shadow-inner">
                      <CheckCircle2 className="w-10 h-10" />
                    </div>

                    <div className="space-y-1">
                      <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-700 bg-emerald-100 px-3 py-0.5 rounded-full">
                        Status: BERHASIL DIBUKA
                      </span>
                      <h2 className="text-2xl font-black text-slate-900 font-display tracking-tight">
                        PEMBUKAAN PUPUK BERHASIL
                      </h2>
                      <p className="text-xs text-slate-500">
                        Aktivitas pembukaan pupuk fisik telah divalidasi geofencing dan tercatat di sistem.
                      </p>
                    </div>

                    {/* 4 Valid Badges */}
                    <div className="grid grid-cols-2 gap-2 text-xs font-bold text-emerald-900 pt-2">
                      <div className="p-2 rounded-xl bg-emerald-100/70 border border-emerald-200">
                        ✓ QR Pupuk Valid
                      </div>
                      <div className="p-2 rounded-xl bg-emerald-100/70 border border-emerald-200">
                        ✓ Alokasi Sesuai
                      </div>
                      <div className="p-2 rounded-xl bg-emerald-100/70 border border-emerald-200">
                        ✓ Petani Terverifikasi
                      </div>
                      <div className="p-2 rounded-xl bg-emerald-100/70 border border-emerald-200">
                        ✓ Lokasi Lahan Sesuai
                      </div>
                    </div>

                    {/* Details Box */}
                    <div className="p-4 rounded-2xl bg-white border border-slate-200 text-xs text-left space-y-2.5 shadow-xs">
                      <div className="flex justify-between items-center py-1 border-b border-slate-100">
                        <span className="text-slate-400">Petani:</span>
                        <strong className="text-slate-900">{openSuccessState.petani}</strong>
                      </div>
                      <div className="flex justify-between items-center py-1 border-b border-slate-100">
                        <span className="text-slate-400">ID Pupuk:</span>
                        <strong className="font-mono text-slate-900">{openSuccessState.id_pupuk}</strong>
                      </div>
                      <div className="flex justify-between items-center py-1 border-b border-slate-100">
                        <span className="text-slate-400">Jenis Pupuk:</span>
                        <strong className="text-slate-900">{openSuccessState.jenis_pupuk}</strong>
                      </div>
                      <div className="flex justify-between items-center py-1 border-b border-slate-100">
                        <span className="text-slate-400">Berat:</span>
                        <strong className="text-emerald-700 font-bold">{openSuccessState.jumlah_pupuk}</strong>
                      </div>
                      <div className="flex justify-between items-center py-1 border-b border-slate-100">
                        <span className="text-slate-400">Lahan:</span>
                        <strong className="text-slate-900">{openSuccessState.nama_lahan}</strong>
                      </div>
                      <div className="flex justify-between items-center py-1 border-b border-slate-100">
                        <span className="text-slate-400">Lokasi:</span>
                        <span className="text-emerald-800 font-semibold">GPS Terdeteksi ({openSuccessState.jarak_meter}m)</span>
                      </div>
                      <div className="flex justify-between items-center py-1 border-b border-slate-100">
                        <span className="text-slate-400">Tanggal:</span>
                        <strong className="text-slate-900">{openSuccessState.tanggal}</strong>
                      </div>
                      <div className="flex justify-between items-center py-1">
                        <span className="text-slate-400">Jam:</span>
                        <strong className="text-slate-900">{openSuccessState.waktu}</strong>
                      </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="pt-2 flex flex-col sm:flex-row items-center gap-3">
                      <button
                        onClick={() => setActiveNav('riwayat')}
                        className="w-full py-3.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-lg shadow-emerald-600/30 transition-all flex items-center justify-center gap-2 cursor-pointer"
                      >
                        <History className="w-4 h-4" />
                        <span>[ LIHAT RIWAYAT PEMBUKAAN ]</span>
                      </button>
                      <button
                        onClick={resetPembukaanFlow}
                        className="w-full py-3.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs transition-colors cursor-pointer"
                      >
                        Buka Alokasi Lain
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 9 & 10. HISTORY PEMBUKAAN PUPUK & DETAIL RIWAYAT                          */}
      {/* ========================================================================= */}
      {activeNav === 'riwayat' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs space-y-6">
            <div className="pb-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div>
                <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                  <History className="w-5 h-5 text-emerald-600" />
                  Riwayat Pembukaan Pupuk ({historyList.length})
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Daftar seluruh aktivitas pembukaan karung pupuk subsidi yang telah divalidasi GPS di lahan terdaftar.
                </p>
              </div>
              <span className="text-xs font-bold text-emerald-700 bg-emerald-50 px-3 py-1 rounded-full border border-emerald-200 self-start sm:self-auto">
                Total Digunakan: {totalPupukDigunakan} kg
              </span>
            </div>

            {historyList.length === 0 ? (
              <div className="py-12 text-center">
                <History className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                <p className="text-sm font-bold text-slate-700">Belum Ada Riwayat Pembukaan</p>
                <p className="text-xs text-slate-400 mt-1">
                  Buka pupuk subsidi di petak sawah melalui menu "Pembukaan Pupuk".
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {historyList.map((item, index) => (
                  <div
                    key={item.id || index}
                    onClick={() => setSelectedHistoryDetail(item)}
                    className="p-5 rounded-2xl border border-slate-200 hover:border-emerald-300 hover:shadow-md bg-white transition-all cursor-pointer flex flex-col sm:flex-row sm:items-center justify-between gap-4 group"
                  >
                    <div className="space-y-1.5 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                          <Calendar className="w-3.5 h-3.5 text-emerald-600" />
                          {item.tanggal}
                        </span>
                        <span className="text-slate-300">•</span>
                        <span className="text-xs font-semibold text-slate-500 flex items-center gap-1">
                          <Clock className="w-3.5 h-3.5 text-slate-400" />
                          {item.waktu}
                        </span>
                      </div>

                      <div className="flex items-center gap-3">
                        <h4 className="text-base font-black text-slate-900 group-hover:text-emerald-700 transition-colors">
                          {item.jenis_pupuk}
                        </h4>
                        <span className="text-xs font-extrabold px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                          {item.jumlah_pupuk}
                        </span>
                        {item.id_pupuk && (
                          <span className="text-xs font-mono font-bold px-2 py-0.5 rounded bg-slate-100 text-slate-700">
                            ID: {item.id_pupuk}
                          </span>
                        )}
                      </div>

                      <p className="text-xs text-slate-600 flex items-center gap-1">
                        <MapPin className="w-3.5 h-3.5 text-slate-400" />
                        <span>Lahan: <strong>{item.nama_lahan}</strong></span>
                      </p>

                      <div className="text-[11px] text-slate-400 font-mono">
                        Lokasi: {formatCoord(item.latitude)}, {formatCoord(item.longitude)}
                      </div>
                    </div>

                    <div className="flex sm:flex-col items-center sm:items-end justify-between sm:justify-center gap-2 shrink-0 border-t sm:border-t-0 pt-3 sm:pt-0 border-slate-100">
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                        <CheckCircle2 className="w-3.5 h-3.5" /> {item.status_pembukaan || '✓ Pembukaan Berhasil'}
                      </span>
                      <span className="text-xs font-bold text-emerald-600 group-hover:underline flex items-center gap-1">
                        Lihat Detail <ChevronRight className="w-3.5 h-3.5" />
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODALS SECTION                                                            */}
      {/* ========================================================================= */}

      {/* Modal: Detail Pembukaan Pupuk */}
      {selectedHistoryDetail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-md w-full overflow-hidden p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center">
                  <PackageCheck className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Detail Pembukaan Pupuk</h3>
                  <p className="text-[11px] text-slate-400">Bukti Verifikasi Lapangan Resmi</p>
                </div>
              </div>
              <button
                onClick={() => setSelectedHistoryDetail(null)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-2.5 text-xs">
              <div className="p-2.5 rounded-xl bg-slate-50 flex justify-between items-center">
                <span className="text-slate-500">ID Transaksi:</span>
                <strong className="font-mono text-slate-900 font-bold">{selectedHistoryDetail.id}</strong>
              </div>

              <div className="p-2.5 rounded-xl bg-slate-50 flex justify-between items-center">
                <span className="text-slate-500">ID QR Pupuk:</span>
                <strong className="font-mono text-slate-900 font-bold">{selectedHistoryDetail.id_pupuk || 'EPU-000123'}</strong>
              </div>

              <div className="p-2.5 rounded-xl bg-slate-50 flex justify-between items-center">
                <span className="text-slate-500">Jenis Pupuk:</span>
                <strong className="text-slate-900 font-black">{selectedHistoryDetail.jenis_pupuk}</strong>
              </div>

              <div className="p-2.5 rounded-xl bg-slate-50 flex justify-between items-center">
                <span className="text-slate-500">Berat Pupuk:</span>
                <strong className="text-emerald-700 font-black">{selectedHistoryDetail.jumlah_pupuk}</strong>
              </div>

              <div className="p-2.5 rounded-xl bg-slate-50 flex justify-between items-center">
                <span className="text-slate-500">Nama Petani:</span>
                <strong className="text-slate-900">{selectedHistoryDetail.nama_petani || farmer?.nama || user?.nama || 'Budi Santoso'}</strong>
              </div>

              <div className="p-2.5 rounded-xl bg-slate-50">
                <span className="text-slate-400 block text-[10px]">Lahan:</span>
                <strong className="text-slate-800 block mt-0.5">{selectedHistoryDetail.nama_lahan}</strong>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div className="p-2.5 rounded-xl bg-slate-50">
                  <span className="text-slate-400 block text-[10px]">Tanggal:</span>
                  <strong className="text-slate-800">{selectedHistoryDetail.tanggal}</strong>
                </div>
                <div className="p-2.5 rounded-xl bg-slate-50">
                  <span className="text-slate-400 block text-[10px]">Jam:</span>
                  <strong className="text-slate-800">{selectedHistoryDetail.waktu}</strong>
                </div>
              </div>

              <div className="p-2.5 rounded-xl bg-slate-50">
                <span className="text-slate-400 block text-[10px]">Koordinat GPS:</span>
                <strong className="font-mono text-slate-800 block mt-0.5">
                  {selectedHistoryDetail.latitude}, {selectedHistoryDetail.longitude}
                </strong>
              </div>

              <div className="p-2.5 rounded-xl bg-slate-50 flex justify-between items-center">
                <span className="text-slate-500">Jarak dari titik lahan:</span>
                <strong className="font-mono text-slate-900">{selectedHistoryDetail.jarak_meter || 18} meter</strong>
              </div>

              {/* Status Validasi */}
              <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-950 space-y-1.5">
                <span className="text-[11px] font-bold text-emerald-900 uppercase block">Status Validasi:</span>
                <div className="grid grid-cols-3 gap-1 text-[11px] font-bold">
                  <span className="text-emerald-800">✓ QR Valid</span>
                  <span className="text-emerald-800">✓ Alokasi Sesuai</span>
                  <span className="text-emerald-800">✓ GPS Sesuai</span>
                </div>
              </div>

              {/* Status Akhir */}
              <div className="p-3 rounded-xl bg-slate-900 text-white flex justify-between items-center">
                <span className="text-xs text-slate-300">Status Akhir:</span>
                <span className="text-xs font-black text-emerald-400 font-mono tracking-wider">
                  {selectedHistoryDetail.status_pembukaan || 'PEMBUKAAN BERHASIL'}
                </span>
              </div>
            </div>

            <button
              onClick={() => setSelectedHistoryDetail(null)}
              className="w-full py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs transition-colors cursor-pointer"
            >
              Tutup
            </button>
          </div>
        </div>
      )}

      {/* Modal: Detail Lahan Pertanian */}
      {selectedLandDetail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-lg w-full overflow-hidden p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                <Tractor className="w-4 h-4 text-emerald-600" />
                Detail Lahan: {selectedLandDetail.lokasi_deskripsi}
              </h3>
              <button
                onClick={() => setSelectedLandDetail(null)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Photo preview in modal */}
            {selectedLandDetail.foto_lahan_url && (
              <div className="rounded-xl overflow-hidden aspect-16/9 bg-slate-100 border border-slate-200">
                <img
                  src={selectedLandDetail.foto_lahan_url}
                  alt={selectedLandDetail.lokasi_deskripsi}
                  className="w-full h-full object-cover"
                />
              </div>
            )}

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-400 block text-[11px]">Luas Lahan:</span>
                <strong className="text-slate-900 font-bold text-sm">{selectedLandDetail.luas_m2} m²</strong>
              </div>
              <div className="p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-400 block text-[11px]">Komoditas:</span>
                <strong className="text-emerald-700 font-bold text-sm">{selectedLandDetail.commodity?.nama_komoditas || 'Padi'}</strong>
              </div>
              <div className="p-3 bg-slate-50 rounded-xl col-span-2">
                <span className="text-slate-400 block text-[11px]">Alamat Lengkap:</span>
                <strong className="text-slate-800">{selectedLandDetail.alamat_lahan}</strong>
              </div>
              <div className="p-3 bg-slate-50 rounded-xl col-span-2">
                <span className="text-slate-400 block text-[11px]">Koordinat Geospasial GPS:</span>
                <strong className="font-mono text-emerald-800">{selectedLandDetail.latitude}, {selectedLandDetail.longitude}</strong>
              </div>
            </div>

            <div className="pt-2 flex justify-end gap-2">
              <button
                onClick={() => setSelectedLandDetail(null)}
                className="w-full py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs cursor-pointer"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Tambah Lahan Baru */}
      {showAddLandModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-xl w-full overflow-hidden max-h-[92vh] flex flex-col">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <div>
                <h3 className="text-base font-bold text-slate-900">
                  Tambah Lahan Pertanian Baru
                </h3>
                <p className="text-xs text-slate-500">
                  Daftarkan petak sawah baru milik/sewa Anda untuk alokasi subsidi pupuk
                </p>
              </div>
              <button
                onClick={() => setShowAddLandModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateLand} className="p-6 overflow-y-auto space-y-4 text-xs">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Nama / Blok Lahan <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  placeholder="Contoh: Sawah Blok Timur Kebondalem"
                  value={landFormData.lokasi_deskripsi}
                  onChange={(e) => setLandFormData({ ...landFormData, lokasi_deskripsi: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  required
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Luas Lahan (m²) <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="number"
                    min="100"
                    placeholder="Contoh: 12000"
                    value={landFormData.luas_m2}
                    onChange={(e) => setLandFormData({ ...landFormData, luas_m2: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden font-bold"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Jenis Komoditas
                  </label>
                  <select
                    value={landFormData.commodity_id}
                    onChange={(e) => setLandFormData({ ...landFormData, commodity_id: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  >
                    {commodities.map((c) => (
                      <option key={c.id} value={c.id}>{c.nama_komoditas}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Alamat Lengkap Lahan <span className="text-rose-500">*</span>
                </label>
                <textarea
                  rows={2}
                  placeholder="Dusun, RT/RW, Desa, Kecamatan"
                  value={landFormData.alamat_lahan}
                  onChange={(e) => setLandFormData({ ...landFormData, alamat_lahan: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  required
                />
              </div>

              {/* Map Coordinates Picker for new Land */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Titik Koordinat GPS Lahan
                </label>
                <MapPicker
                  latitude={landFormData.latitude}
                  longitude={landFormData.longitude}
                  onChange={(lat, lng) => setLandFormData({ ...landFormData, latitude: lat, longitude: lng })}
                />
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddLandModal(false)}
                  className="px-4 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-md shadow-emerald-200 transition-colors cursor-pointer"
                >
                  Simpan Lahan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Ajukan Subsidi Baru (Global Quick Modal) */}
      {showApplyModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-2xl w-full overflow-hidden max-h-[92vh] flex flex-col">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <div>
                <h3 className="text-base font-bold text-slate-900">
                  Form Pengajuan Subsidi Pupuk
                </h3>
                <p className="text-xs text-slate-500">
                  Pilih lahan terdaftar dan tentukan volume kuota pupuk yang dimohon
                </p>
              </div>
              <button
                onClick={() => setShowApplyModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateApplication} className="p-6 overflow-y-auto space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Pilih Lahan Pertanian <span className="text-rose-500">*</span>
                </label>
                <select
                  value={formData.land_id}
                  onChange={handleLandSelectChange}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  required
                >
                  <option value="">-- Pilih Lahan Terdaftar --</option>
                  {lands.map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.lokasi_deskripsi || 'Lahan Sawah'} — {l.luas_m2} m² ({l.commodity?.nama_komoditas || 'Padi'})
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Jenis Pupuk Bersubsidi <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={formData.fertilizer_id}
                    onChange={(e) => setFormData({ ...formData, fertilizer_id: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                    required
                  >
                    <option value="">-- Pilih Pupuk --</option>
                    {fertilizers.map((f) => (
                      <option key={f.id} value={f.id}>
                        {f.nama_pupuk} (Satuan: {f.satuan})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">
                    Jumlah yang Diajukan (kg) <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="number"
                    min="10"
                    max="1000"
                    step="5"
                    placeholder="Contoh: 100"
                    value={formData.jumlah_diajukan}
                    onChange={(e) => setFormData({ ...formData, jumlah_diajukan: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden font-bold"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Alamat Lokasi Lahan <span className="text-rose-500">*</span>
                </label>
                <textarea
                  rows={2}
                  value={formData.alamat_lahan}
                  onChange={(e) => setFormData({ ...formData, alamat_lahan: e.target.value })}
                  placeholder="Alamat lahan pertanian lengkap"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-xs text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Titik Koordinat GPS Lahan
                </label>
                <MapPicker
                  latitude={formData.latitude}
                  longitude={formData.longitude}
                  onChange={(lat, lng) => setFormData({ ...formData, latitude: lat, longitude: lng })}
                />
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowApplyModal(false)}
                  className="px-4 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
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

      {/* Modal: Revisi Berkas */}
      {showReviseModal && selectedApp && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-150">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 max-w-lg w-full overflow-hidden max-h-[90vh] flex flex-col">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-orange-50">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-orange-600" />
                <div>
                  <h3 className="text-sm font-bold text-slate-900">
                    Perbaikan Dokumen Persyaratan (Pengajuan #{selectedApp.id})
                  </h3>
                  <p className="text-[11px] text-slate-500">
                    Unggah kembali foto KTP atau bukti lahan sesuai catatan Admin Dinas
                  </p>
                </div>
              </div>
              <button
                onClick={() => setShowReviseModal(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleReviseSubmit} className="p-6 overflow-y-auto space-y-4 text-xs">
              {selectedApp.catatan_admin_berkas && (
                <div className="p-3 rounded-xl bg-amber-50 border border-amber-200 text-amber-900">
                  <strong className="block text-[11px] uppercase font-bold text-amber-800">Catatan Perbaikan dari Admin:</strong>
                  <p className="mt-0.5 leading-relaxed">{selectedApp.catatan_admin_berkas}</p>
                </div>
              )}

              <FileUploadZone
                label="Unggah Ulang Foto KTP (Jika Diminta)"
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
                  className="px-4 py-2 rounded-xl border border-slate-300 text-xs font-bold text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
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

      {/* Lightbox Photo Viewer Modal */}
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
