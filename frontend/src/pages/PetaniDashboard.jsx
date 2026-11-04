import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Html5Qrcode } from 'html5-qrcode';
import { 
  LayoutDashboard, User, Tractor, MapPin, Calendar, FileText,
  AlertTriangle, RefreshCw, Eye, CheckCircle2, ChevronRight,
  ShieldCheck, ArrowUpRight, Sparkles, X, Map, Download, Plus,
  PieChart, History, PlusCircle, LogOut, Check, Layers, PackageCheck,
  Crosshair, Navigation, Compass, Shield, Smartphone, Clock, ArrowRight,
  Camera, CheckCircle, XCircle, Sprout, Scan, Box
} from 'lucide-react';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';
import { 
  applicationsApi, farmersApi, landsApi, distributionsApi, filesApi
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
  const [historyList, setHistoryList] = useState([]);
  const [allocations, setAllocations] = useState([]);
  const [loading, setLoading] = useState(true);

  // Modals state
  const [showApplyModal, setShowApplyModal] = useState(false);
  const [showReviseModal, setShowReviseModal] = useState(false);
  const [showAddLandModal, setShowAddLandModal] = useState(false);
  const [selectedLandDetail, setSelectedLandDetail] = useState(null);
  const [selectedHistoryDetail, setSelectedHistoryDetail] = useState(null);
  const [selectedApp, setSelectedApp] = useState(null);
  const [isEditingKtp, setIsEditingKtp] = useState(false);
  const [isEditingLandDocuments, setIsEditingLandDocuments] = useState(false);
  const [landPhotoDraft, setLandPhotoDraft] = useState('');
  const [certificateDraft, setCertificateDraft] = useState('');
  const [isSavingLandDocuments, setIsSavingLandDocuments] = useState(false);

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
    latitude: null,
    longitude: null,
  });

  // Add Land Form State
  const [landFormData, setLandFormData] = useState({
    lokasi_deskripsi: '',
    luas_m2: '',
    commodity_id: '',
    alamat_lahan: '',
    status_kepemilikan: 'MILIK',
    latitude: null,
    longitude: null,
    foto_lahan_url: '',
    dokumen_sertifikat_url: '',
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
  const [pupukPhotoFile, setPupukPhotoFile] = useState(null);
  const [scannerError, setScannerError] = useState(null);
  const handleScanBagIdRef = useRef(null);
  const [scannedBag, setScannedBag] = useState(null);
  const [qrValidation, setQrValidation] = useState({
    isScanned: false,
    isValidQr: false,
    isAlreadyUsed: false,
    isAllocationMatch: true,
    message: '',
  });

  // GPS State
  const [currentGps, setCurrentGps] = useState(null);
  const [gpsLoading, setGpsLoading] = useState(false);
  const [gpsError, setGpsError] = useState(null);
  const [isProcessingOpen, setIsProcessingOpen] = useState(false);
  const [openSuccessState, setOpenSuccessState] = useState(null); // stores final success data

  // Fetch Dashboard Data
  const fetchData = async () => {
    setLoading(true);
    try {
      const [fRes, landsRes, appsRes, fertsRes, statsRes, comRes, scansRes, distributionsRes] = await Promise.all([
        farmersApi.getMe(),
        landsApi.getAll(),
        applicationsApi.getAll(),
        farmersApi.getFertilizers(),
        applicationsApi.getPetaniStats(),
        farmersApi.getCommodities().catch(() => ({ data: [] })),
        distributionsApi.getMyScans(),
        distributionsApi.getMyDistributions(),
      ]);

      setFarmer(fRes.data);
      const activeFarmerId = fRes.data?.id;
      setLands((Array.isArray(landsRes.data) ? landsRes.data : [])
        .filter((land) => land.farmer_id === activeFarmerId));
      setApplications((Array.isArray(appsRes.data) ? appsRes.data : [])
        .filter((app) => app.farmer_id === activeFarmerId));
      setFertilizers(fertsRes.data || []);
      setStats(statsRes.data || null);
      setCommodities(comRes.data || []);
      setHistoryList(scansRes.data || []);
      setAllocations((distributionsRes.data || [])
        .filter((distribution) => distribution.status_penyaluran === 'MENUNGGU_PENGAMBILAN')
        .map((distribution) => ({
          id: distribution.id,
          qr_token: distribution.qr_code_hash,
          jenis_pupuk: distribution.application?.fertilizer?.nama_pupuk || 'Pupuk belum tersedia',
          jumlah_kg: Number(distribution.jumlah_disalurkan),
          nama_lahan: distribution.application?.land?.lokasi_deskripsi
            || distribution.application?.land?.alamat_lahan
            || 'Lahan belum tersedia',
          alamat_lahan: distribution.application?.land?.alamat_lahan || 'Alamat lahan belum tersedia',
          latitude: distribution.application?.land?.latitude ?? distribution.application?.latitude,
          longitude: distribution.application?.land?.longitude ?? distribution.application?.longitude,
          status: distribution.status_penyaluran,
        })));

      if (landsRes.data && landsRes.data.length > 0) {
        setFormData((prev) => ({
          ...prev,
          land_id: landsRes.data[0].id,
          alamat_lahan: landsRes.data[0].alamat_lahan,
          latitude: landsRes.data[0].latitude ?? null,
          longitude: landsRes.data[0].longitude ?? null,
        }));
      }
      if (fertsRes.data && fertsRes.data.length > 0) {
        setFormData((prev) => ({ ...prev, fertilizer_id: fertsRes.data[0].id }));
      }

    } catch (err) {
      console.error('Error fetching dashboard data:', err);
      toast.error('Gagal memuat data Petani dari server.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    const refreshOnFocus = () => fetchData();
    window.addEventListener('focus', refreshOnFocus);
    return () => window.removeEventListener('focus', refreshOnFocus);
  }, []);

  useEffect(() => {
    if (activeNav !== 'pembukaan' || pembukaanStep !== 'scan' || !isScannerActive) return undefined;
    const element = document.getElementById('petani-qr-reader');
    if (!element) return undefined;
    const scanner = new Html5Qrcode('petani-qr-reader');
    let disposed = false;
    let hasDecoded = false;
    scanner.start(
      { facingMode: 'environment' },
      { fps: 10, qrbox: { width: 240, height: 240 } },
      (decodedText) => {
        if (disposed || hasDecoded) return;
        hasDecoded = true;
        setIsScannerActive(false);
        handleScanBagIdRef.current?.(decodedText);
      },
      () => {},
    ).then(() => {
      if (disposed && scanner.isScanning) {
        return scanner.stop().then(() => scanner.clear());
      }
      return undefined;
    }).catch((error) => {
      if (!disposed) {
        console.error('Unable to start QR camera:', error);
        setScannerError('Kamera tidak dapat dibuka. Izinkan akses kamera dan coba lagi.');
        setIsScannerActive(false);
      }
    });

    return () => {
      disposed = true;
      if (scanner.isScanning) {
        scanner.stop()
          .then(() => scanner.clear())
          .catch((error) => console.error('Unable to stop QR camera:', error));
      }
    };
  }, [activeNav, pembukaanStep, isScannerActive]);

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
  const targetLand = lands[0] || null;

  // GPS evidence must be checked against the selected allocation's land.
  const activeAllocLat = selectedAllocation?.latitude ?? null;
  const activeAllocLon = selectedAllocation?.longitude ?? null;
  const hasActiveLandCoordinates = activeAllocLat !== null
    && activeAllocLon !== null
    && Number.isFinite(Number(activeAllocLat))
    && Number.isFinite(Number(activeAllocLon));

  const displayedDistance = currentGps && hasActiveLandCoordinates
    ? calculateHaversineMeters(
      currentGps.latitude,
      currentGps.longitude,
      activeAllocLat,
      activeAllocLon,
    )
    : null;
  const isLocationValid = Boolean(currentGps);

  // Reset pembukaan flow to initial state
  const resetPembukaanFlow = () => {
    setPembukaanStep('select');
    setSelectedAllocation(null);
    setIsScannerActive(false);
    setPupukPhotoFile(null);
    setCurrentGps(null);
    setScannedBag(null);
    setQrValidation({ isScanned: false, isValidQr: false, isAlreadyUsed: false, isAllocationMatch: true, message: '' });
    setOpenSuccessState(null);
    setGpsError(null);
    setScannerError(null);
  };

  // Handler for Scanning Physical Bag QR Code
  const handleScanBagId = useCallback((bagIdToUse) => {
    const rawCode = String(bagIdToUse || '').trim();
    if (!rawCode) {
      toast.error('Masukkan atau pindai ID QR Pupuk pada karung.');
      return;
    }

    if (!selectedAllocation || rawCode !== selectedAllocation.qr_token) {
      setScannedBag(null);
      setQrValidation({
        isScanned: true,
        isValidQr: false,
        isAlreadyUsed: false,
        message: selectedAllocation
          ? 'QR Code tidak sesuai dengan alokasi pengajuan ini.'
          : 'Pilih alokasi pupuk yang tersedia sebelum memindai QR.',
      });
      setIsScannerActive(false);
      setPembukaanStep('result');
      toast.error('QR Pupuk Tidak Valid!');
      return;
    }

    setScannedBag({
      idPupuk: rawCode,
      jenisPupuk: selectedAllocation.jenis_pupuk,
      beratKg: selectedAllocation.jumlah_kg,
      statusBag: 'SIAP DIBUKA',
      isAllocationMatch: true,
    });

    setQrValidation({
      isScanned: true,
      isValidQr: true,
      isAlreadyUsed: false,
      isAllocationMatch: true,
      message: 'QR Pupuk sesuai dengan alokasi pengajuan.',
    });

    setIsScannerActive(false);
    setPembukaanStep('result');
    toast.success(`QR Pupuk ${rawCode} Berhasil Dipindai!`);
  }, [selectedAllocation]);

  useEffect(() => {
    handleScanBagIdRef.current = handleScanBagId;
  }, [handleScanBagId]);

  // Confirm Pembukaan Pupuk Handler
  const handleConfirmPembukaanPupuk = async () => {
    if (!scannedBag || !qrValidation.isValidQr) {
      toast.error('QR Pupuk belum valid.');
      return;
    }

    if (!currentGps) {
      toast.error('Ambil lokasi GPS perangkat sebelum melanjutkan.');
      return;
    }

    if (!hasActiveLandCoordinates) {
      toast.error('Koordinat lahan pada alokasi ini belum tersedia.');
      return;
    }

    if (!pupukPhotoFile) {
      toast.error('Foto karung yang sudah dibuka wajib diunggah.');
      return;
    }

    setIsProcessingOpen(true);
    const toastId = toast.loading('Memvalidasi & mengonfirmasi pembukaan karung pupuk...');

    const latToUse = currentGps.latitude;
    const lngToUse = currentGps.longitude;

    try {
      const photoResponse = await filesApi.upload(pupukPhotoFile, 'pupuk');
      const photoUrl = photoResponse.data?.url;
      if (typeof photoUrl !== 'string' || !photoUrl.startsWith('/files/pupuk/')) {
        throw new Error('Server tidak mengembalikan lokasi foto pupuk yang valid.');
      }
      // Send scan data to backend
      const scanRes = await distributionsApi.scanQr({
        qr_token: scannedBag.idPupuk,
        latitude: latToUse,
        longitude: lngToUse,
        foto_pupuk_url: photoUrl,
      });
      if (!scanRes.data?.success) {
        const message = scanRes.data?.message || 'QR pupuk tidak dapat divalidasi oleh server.';
        setQrValidation((current) => ({
          ...current,
          isValidQr: false,
          isAlreadyUsed: scanRes.data?.status === 'ALREADY_CLAIMED',
          message,
        }));
        toast.error(message, { id: toastId });
        return;
      }

      const distribution = scanRes.data.distribution;
      const app = distribution?.application;
      const now = distribution?.tanggal_penyaluran
        ? new Date(distribution.tanggal_penyaluran)
        : new Date();
      const successData = {
        id: distribution?.id,
        id_pupuk: scannedBag.idPupuk,
        tanggal: now.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }),
        waktu: `${now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })} WIB`,
        jenis_pupuk: app?.fertilizer?.nama_pupuk || scannedBag.jenisPupuk,
        jumlah_pupuk: `${distribution?.jumlah_disalurkan ?? scannedBag.beratKg} kg`,
        jumlah_kg: Number(distribution?.jumlah_disalurkan ?? scannedBag.beratKg),
        nama_lahan: app?.land?.lokasi_deskripsi || app?.land?.alamat_lahan || selectedAllocation?.nama_lahan || 'Lahan belum tersedia',
        alamat_lahan: app?.land?.alamat_lahan || selectedAllocation?.alamat_lahan || 'Alamat lahan belum tersedia',
        latitude: latToUse,
        longitude: lngToUse,
        jarak_meter: displayedDistance,
        status_pembukaan: 'Pembukaan Berhasil',
        status_validasi: 'VALID',
        verifikasi_lokasi: 'Lokasi sesuai dengan lahan terdaftar',
      };
      setOpenSuccessState({ ...successData, petani: farmer?.nama || user?.nama || 'Petani' });
      setPembukaanStep('success');
      setPupukPhotoFile(null);
      await fetchData();

      toast.success(
        `PUPUK BERHASIL DIBUKA! ${scannedBag.jenisPupuk} ${scannedBag.beratKg} kg sukses dicatat.`,
        { id: toastId, duration: 6000 }
      );
    } catch (err) {
      toast.error(
        err.response?.data?.detail || err.message || 'Gagal memproses pembukaan pupuk.',
        { id: toastId },
      );
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

  const approvedApplications = applications.filter((app) =>
    ['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN'].includes(app.status)
  );
  const kuotaDisetujuiUrea = approvedApplications
    .filter((app) => app.fertilizer?.nama_pupuk?.toLowerCase().includes('urea'))
    .reduce((sum, app) => sum + Number(app.jumlah_disetujui || 0), 0);
  const sisaKuotaUrea = Math.max(0, kuotaDisetujuiUrea - totalUreaUsed);

  const kuotaDisetujuiNpk = approvedApplications
    .filter((app) => app.fertilizer?.nama_pupuk?.toLowerCase().includes('npk'))
    .reduce((sum, app) => sum + Number(app.jumlah_disetujui || 0), 0);
  const sisaKuotaNpk = Math.max(0, kuotaDisetujuiNpk - totalNpkUsed);
  const ureaUsagePercent = kuotaDisetujuiUrea > 0 ? Math.round((totalUreaUsed / kuotaDisetujuiUrea) * 100) : 0;
  const npkUsagePercent = kuotaDisetujuiNpk > 0 ? Math.round((totalNpkUsed / kuotaDisetujuiNpk) * 100) : 0;

  // Form Handlers
  const handleLandSelectChange = (e) => {
    const selectedLandId = parseInt(e.target.value);
    const selectedLand = lands.find((l) => l.id === selectedLandId);
    if (selectedLand) {
      setFormData((prev) => ({
        ...prev,
        land_id: selectedLandId,
        alamat_lahan: selectedLand.alamat_lahan,
        latitude: selectedLand.latitude ?? null,
        longitude: selectedLand.longitude ?? null,
      }));
    }
  };

  const handleCreateApplication = async (e) => {
    e.preventDefault();
    if (!formData.land_id || !formData.fertilizer_id || !formData.jumlah_diajukan) {
      toast.error('Harap lengkapi semua kolom yang wajib diisi.');
      return;
    }
    const selectedLand = lands.find((land) => land.id === Number(formData.land_id));
    if (!farmer?.foto_ktp_url) {
      toast.error('Unggah foto KTP pada menu Profil sebelum mengirim pengajuan.');
      setActiveNav('profil');
      return;
    }
    if (!selectedLand?.foto_lahan_url) {
      toast.error('Unggah foto lahan pada data lahan sebelum mengirim pengajuan.');
      setActiveNav('lahan');
      return;
    }
    if (
      formData.latitude == null || formData.longitude == null
      || String(formData.latitude).trim() === '' || String(formData.longitude).trim() === ''
      || !Number.isFinite(Number(formData.latitude))
      || !Number.isFinite(Number(formData.longitude))
    ) {
      toast.error('Titik koordinat GPS lahan wajib ditentukan sebelum mengirim pengajuan.');
      return;
    }
    const requestedKg = Number(formData.jumlah_diajukan);
    if (!Number.isInteger(requestedKg) || requestedKg < 25 || requestedKg % 25 !== 0) {
      toast.error('Jumlah pengajuan harus kelipatan 25 kg.');
      return;
    }

    const toastId = toast.loading('Mengirim pengajuan subsidi...');
    try {
      await applicationsApi.create({
        land_id: parseInt(formData.land_id),
        fertilizer_id: parseInt(formData.fertilizer_id),
        jumlah_diajukan: requestedKg,
        alamat_lahan: formData.alamat_lahan,
        latitude: formData.latitude,
        longitude: formData.longitude,
      });
      setShowApplyModal(false);
      await fetchData();
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
    if (!landFormData.foto_lahan_url) {
      toast.error('Unggah foto kondisi lahan sebelum menyimpan data lahan.');
      return;
    }
    if (
      !landFormData.commodity_id
      || landFormData.latitude == null || landFormData.longitude == null
      || String(landFormData.latitude).trim() === '' || String(landFormData.longitude).trim() === ''
      || !Number.isFinite(Number(landFormData.latitude))
      || !Number.isFinite(Number(landFormData.longitude))
    ) {
      toast.error('Pilih komoditas dan tentukan titik koordinat GPS lahan.');
      return;
    }

    const toastId = toast.loading('Menyimpan data lahan baru...');
    try {
      await landsApi.create({
        lokasi_deskripsi: landFormData.lokasi_deskripsi,
        luas_m2: parseFloat(landFormData.luas_m2),
        alamat_lahan: landFormData.alamat_lahan,
        commodity_id: parseInt(landFormData.commodity_id),
        status_kepemilikan: landFormData.status_kepemilikan,
        latitude: landFormData.latitude,
        longitude: landFormData.longitude,
        foto_lahan_url: landFormData.foto_lahan_url,
        dokumen_sertifikat_url: landFormData.dokumen_sertifikat_url || null,
      });
      setShowAddLandModal(false);
      await fetchData();
      toast.success('Lahan pertanian berhasil didaftarkan!', { id: toastId });
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal mendaftarkan lahan.', { id: toastId });
    }
  };

  const handleSaveLandDocuments = async () => {
    if (!selectedLandDetail || isSavingLandDocuments) return;
    setIsSavingLandDocuments(true);
    const toastId = toast.loading('Menyimpan perubahan dokumen lahan...');
    try {
      const response = await landsApi.update(selectedLandDetail.id, {
        foto_lahan_url: landPhotoDraft || null,
        dokumen_sertifikat_url: certificateDraft || null,
      });
      setSelectedLandDetail(response.data);
      setIsEditingLandDocuments(false);
      await fetchData();
      toast.success('Dokumen lahan diperbarui. Pengajuan yang menunggu akan ditinjau ulang Admin.', { id: toastId });
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Gagal memperbarui dokumen lahan.', { id: toastId });
    } finally {
      setIsSavingLandDocuments(false);
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
      await fetchData();
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
    { id: 'pengajuan', label: 'Pengajuan Subsidi', icon: FileText },
    { id: 'status', label: 'Status Pengajuan', icon: Clock },
    { id: 'kuota', label: 'Kuota Pupuk', icon: PieChart },
    { id: 'pembukaan', label: 'Pembukaan Pupuk', icon: Scan, special: true },
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

  const displayApplications = applications.slice(0, 2);

  return (
    <div className="space-y-6 pb-16 font-sans">
      {/* Top Banner Header */}
      <div className="rounded-3xl bg-[#064e3b] text-white p-6 sm:p-8 relative overflow-hidden shadow-lg border border-emerald-800/40">
        <div className="relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#043e2e]/70 border border-emerald-500/30 text-emerald-300 text-[11px] font-semibold tracking-wider uppercase mb-3">
            <Sparkles className="w-3.5 h-3.5 text-emerald-300" />
            PORTAL PETANI & KELOMPOK TANI KABUPATEN MOJOKERTO
          </div>
          <h1 className="text-2xl sm:text-3xl font-black font-display tracking-tight text-white">
            Selamat Datang, {farmer?.nama || user?.nama || 'Petani'}!
          </h1>
          <p className="mt-1.5 text-xs sm:text-sm text-emerald-100/90 max-w-2xl leading-relaxed">
            Sistem resmi verifikasi subsidi, pemantauan kuota, dan pemindaian QR Code pada karung pupuk fisik berbasis GPS geofencing.
          </p>
        </div>
      </div>

      {/* Main Navigation Bar for User / Petani */}
      <div className="bg-white rounded-2xl p-1.5 border border-slate-200/80 shadow-xs flex items-center gap-1.5 overflow-x-auto scrollbar-none">
        {USER_NAV_ITEMS.map((item) => {
          const Icon = item.icon;
          const isActive = activeNav === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveNav(item.id)}
              className={`flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-semibold transition-all shrink-0 cursor-pointer ${
                isActive
                  ? 'bg-[#059669] text-white shadow-xs font-bold'
                  : item.special
                  ? 'border border-emerald-400 bg-emerald-50/70 text-emerald-800 hover:bg-emerald-100'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50'
              }`}
            >
              <Icon className={`w-4 h-4 ${isActive ? 'text-white' : item.special ? 'text-emerald-700' : 'text-slate-400'}`} />
              <span>{item.label}</span>
              {item.special && !isActive && (
                <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" />
              )}
            </button>
          );
        })}
      </div>

      {/* ========================================================================= */}
      {/* 1. DASHBOARD VIEW (RINGKASAN & KPI CARDS)                                 */}
      {/* ========================================================================= */}
      {activeNav === 'dashboard' && (
        <div className="space-y-6 animate-in fade-in duration-200">
          {/* KPI Cards Ringkasan */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
            <KPICard
              title="SISA KUOTA UREA"
              value={`${sisaKuotaUrea} kg`}
              subtitle={`Dari total kuota ${kuotaDisetujuiUrea} kg`}
              icon={Sprout}
              color="emerald"
              badge="Subsidi"
            />
            <KPICard
              title="SISA KUOTA NPK"
              value={`${sisaKuotaNpk} kg`}
              subtitle={`Dari total kuota ${kuotaDisetujuiNpk} kg`}
              icon={Tractor}
              color="blue"
              badge="Subsidi"
            />
            <KPICard
              title="PENGAJUAN BERJALAN"
              value={stats?.aktif !== undefined ? stats.aktif : 0}
              subtitle="Tahap Verifikasi & Survei"
              icon={RefreshCw}
              color="amber"
              badge="Aktif"
            />
            <KPICard
              title="TOTAL PUPUK SUDAH DIGUNAKAN"
              value={`${totalPupukDigunakan} kg`}
              subtitle="Divalidasi GPS di Lahan"
              icon={PackageCheck}
              color="purple"
              badge="Tervalidasi"
            />
          </div>

          {/* 2-Column: Profil Petani & Ringkasan Kuota */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Quick Profile Summary */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-xs flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3.5 border-b border-slate-100">
                  <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                    <User className="w-4 h-4 text-emerald-600" />
                    Profil Petani
                  </h2>
                  <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200/60">
                    <Check className="w-3 h-3 text-emerald-600 stroke-[2.5]" /> Status akun
                  </span>
                </div>

                <div className="mt-4 space-y-3.5 text-xs">
                  <div>
                    <span className="text-slate-400 block text-[11px] font-medium">Nama Lengkap</span>
                    <span className="font-bold text-slate-900 text-sm">{farmer?.nama || user?.nama || 'Belum tersedia'}</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px] font-medium">NIK</span>
                    <span className="font-mono font-bold text-slate-900 text-xs">{farmer?.nik || 'Belum tersedia'}</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px] font-medium">Kelompok Tani (Poktan)</span>
                    <span className="font-semibold text-slate-900">{farmer?.farmer_group?.nama_kelompok || 'Belum tersedia'}</span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px] font-medium">Nomor HP / WhatsApp</span>
                    <span className="font-semibold text-slate-900">{farmer?.kontak || 'Belum tersedia'}</span>
                  </div>
                </div>
              </div>

              <button
                onClick={() => setActiveNav('profil')}
                className="mt-5 w-full py-2.5 rounded-xl border border-slate-200/90 hover:bg-slate-50 text-slate-700 text-xs font-semibold transition-colors flex items-center justify-center gap-1 cursor-pointer"
              >
                <span>Lihat Profil Selengkapnya</span>
                <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
              </button>
            </div>

            {/* Quick Kuota Summary */}
            <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-slate-200/80 shadow-xs space-y-5">
              <div className="flex items-center justify-between pb-3.5 border-b border-slate-100">
                <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                  <Clock className="w-4 h-4 text-emerald-600" />
                  Ringkasan Kuota Pupuk Saya (Musim Tanam 2026)
                </h2>
                <button
                  onClick={() => setActiveNav('kuota')}
                  className="text-xs text-emerald-600 hover:text-emerald-700 font-semibold flex items-center gap-1 cursor-pointer"
                >
                  <span>Detail Kuota</span> <ChevronRight className="w-3.5 h-3.5" />
                </button>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Urea Progress */}
                <div className="p-4 rounded-xl border border-slate-100 bg-slate-50/50 space-y-3 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-slate-800">UREA BERSUBSIDI</span>
                      <span className="text-[11px] font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200/50 px-2 py-0.5 rounded">
                        Sisa {sisaKuotaUrea} kg
                      </span>
                    </div>
                    <div className="mt-3 space-y-1.5 text-xs text-slate-600">
                      <div className="flex justify-between">
                        <span className="text-slate-500">Kuota Disetujui:</span>
                        <strong className="text-slate-900">{kuotaDisetujuiUrea} kg</strong>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-500">Sudah Digunakan:</span>
                        <strong className="text-slate-900">{totalUreaUsed} kg</strong>
                      </div>
                    </div>
                  </div>
                  <div>
                    {/* Progress Bar */}
                    <div className="w-full bg-slate-200/80 h-2 rounded-full overflow-hidden mt-2">
                      <div
                        className="bg-emerald-600 h-full rounded-full transition-all duration-500"
                        style={{ width: `${Math.min(100, ureaUsagePercent)}%` }}
                      />
                    </div>
                    <p className="text-[10px] text-slate-400 text-right mt-1.5">
                      {ureaUsagePercent}% kuota terpakai
                    </p>
                  </div>
                </div>

                {/* NPK Progress */}
                <div className="p-4 rounded-xl border border-slate-100 bg-slate-50/50 space-y-3 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-slate-800">NPK PHONSKA</span>
                      <span className="text-[11px] font-semibold text-blue-700 bg-blue-50 border border-blue-200/50 px-2 py-0.5 rounded">
                        Sisa {sisaKuotaNpk} kg
                      </span>
                    </div>
                    <div className="mt-3 space-y-1.5 text-xs text-slate-600">
                      <div className="flex justify-between">
                        <span className="text-slate-500">Kuota Disetujui:</span>
                        <strong className="text-slate-900">{kuotaDisetujuiNpk} kg</strong>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-500">Sudah Digunakan:</span>
                        <strong className="text-slate-900">{totalNpkUsed} kg</strong>
                      </div>
                    </div>
                  </div>
                  <div>
                    {/* Progress Bar */}
                    <div className="w-full bg-slate-200/80 h-2 rounded-full overflow-hidden mt-2">
                      <div
                        className="bg-blue-600 h-full rounded-full transition-all duration-500"
                        style={{ width: `${Math.min(100, npkUsagePercent)}%` }}
                      />
                    </div>
                    <p className="text-[10px] text-slate-400 text-right mt-1.5">
                      {npkUsagePercent}% kuota terpakai
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Applications Tracker */}
          <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-xs space-y-4">
            <div className="flex items-center justify-between pb-3.5 border-b border-slate-100">
              <div>
                <h2 className="text-sm font-bold text-slate-900">
                  Status Pengajuan Terkini
                </h2>
                <p className="text-xs text-slate-400 mt-0.5">
                  Lacak perkembangan verifikasi dokumen dan penugasan survei lahan
                </p>
              </div>
              <button
                onClick={() => setActiveNav('status')}
                className="text-xs text-emerald-600 hover:text-emerald-700 font-semibold flex items-center gap-1 cursor-pointer"
              >
                <span>Lihat Semua Pengajuan</span> <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>

            <div className="space-y-4">
              {displayApplications.length === 0 && (
                <p className="text-xs text-slate-500">Belum ada pengajuan dari akun ini.</p>
              )}
              {displayApplications.map((app) => (
                <div key={app.id} className="p-5 sm:p-6 rounded-2xl border border-slate-200/80 bg-white space-y-4 shadow-xs">
                  <div className="flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-1.5">
                        <span className="text-xs font-mono font-bold text-slate-400">#{app.id}</span>
                        <strong className="text-sm font-bold text-slate-900 truncate">
                          Pupuk {app.fertilizer?.nama_pupuk || 'Belum tersedia'} — {Number(app.jumlah_diajukan).toLocaleString('id-ID')} {app.fertilizer?.satuan || 'kg'}
                        </strong>
                      </div>
                      <p className="text-xs text-slate-400 mt-0.5 truncate">
                        Lahan: {app.land?.lokasi_deskripsi || app.land?.alamat_lahan || 'Belum tersedia'}
                      </p>
                    </div>
                    <div className="shrink-0">
                      <StatusBadge status={app.status} />
                    </div>
                  </div>
                  <div className="pt-2">
                    <ProgressStepper status={app.status} />
                  </div>
                </div>
              ))}
            </div>
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
                <CheckCircle2 className="w-3.5 h-3.5" /> Status belum tersedia
              </span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Photo KTP Card */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider">
                    Foto KTP Terdaftar
                  </label>
                  {farmer?.foto_ktp_url && !isEditingKtp && (
                    <button
                      type="button"
                      onClick={() => setIsEditingKtp(true)}
                      className="text-[11px] font-bold text-emerald-600 hover:text-emerald-700 hover:underline cursor-pointer"
                    >
                      Ubah Foto
                    </button>
                  )}
                </div>

                {!farmer?.foto_ktp_url || isEditingKtp ? (
                  <div className="space-y-2">
                    <FileUploadZone
                      label={farmer?.foto_ktp_url ? "Unggah Foto KTP Baru" : "Unggah Foto KTP Asli"}
                      category="ktp"
                      initialUrl={farmer?.foto_ktp_url}
                      onUploadSuccess={async (url) => {
                        if (!farmer?.id) {
                          toast.error('Profil belum siap, silakan coba beberapa saat lagi.');
                          return;
                        }
                        const toastId = toast.loading('Menyimpan foto KTP ke profil...');
                        try {
                          const res = await farmersApi.update(farmer.id, { foto_ktp_url: url });
                          setFarmer(res.data);
                          setIsEditingKtp(false);
                          await fetchData();
                          toast.success('Foto KTP berhasil disimpan ke profil!', { id: toastId });
                        } catch (err) {
                          toast.error(err.response?.data?.detail || 'Gagal menyimpan foto KTP.', { id: toastId });
                        }
                      }}
                    />
                    {farmer?.foto_ktp_url && (
                      <button
                        type="button"
                        onClick={() => setIsEditingKtp(false)}
                        className="text-[11px] font-bold text-slate-500 hover:text-slate-800 underline block mx-auto cursor-pointer"
                      >
                        Batal Ubah Foto
                      </button>
                    )}
                  </div>
                ) : (
                  <div>
                    <div 
                      onClick={() => setViewerPhoto({
                        isOpen: true,
                        title: `Foto KTP: ${farmer?.nama || user?.nama || 'Petani'}`,
                        url: farmer.foto_ktp_url,
                        description: `NIK: ${farmer?.nik || 'Belum tersedia'}`
                      })}
                      className="relative rounded-2xl overflow-hidden border border-slate-200 bg-slate-100 aspect-16/10 group cursor-pointer shadow-xs flex items-center justify-center"
                    >
                      <img 
                        src={farmer.foto_ktp_url} 
                        alt="Foto KTP" 
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                      <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-1.5 text-white text-xs font-bold backdrop-blur-xs">
                        <Eye className="w-4 h-4" /> Klik untuk Perbesar KTP
                      </div>
                    </div>
                    <p className="text-[11px] text-slate-400 text-center mt-1.5">
                      Klik foto KTP untuk memeriksa data ukuran penuh
                    </p>
                  </div>
                )}
              </div>

              {/* Farmer Details */}
              <div className="md:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Nama Lengkap</span>
                  <strong className="text-slate-900 text-sm mt-0.5 block">{farmer?.nama || user?.nama || 'Belum tersedia'}</strong>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Nomor Induk Kependudukan (NIK)</span>
                  <strong className="font-mono text-slate-900 text-sm mt-0.5 block">{farmer?.nik || 'Belum tersedia'}</strong>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Nomor HP / WhatsApp</span>
                  <strong className="text-slate-900 text-sm mt-0.5 block">{farmer?.kontak || 'Belum tersedia'}</strong>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Alamat Email</span>
                  <strong className="text-slate-900 text-sm mt-0.5 block">{user?.email || 'Belum tersedia'}</strong>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Kelompok Tani (Poktan)</span>
                  <strong className="text-slate-900 text-sm mt-0.5 block">{farmer?.farmer_group?.nama_kelompok || 'Belum tersedia'}</strong>
                  <span className="text-[10px] text-emerald-700 font-semibold">Wilayah: {farmer?.farmer_group?.wilayah || 'Belum tersedia'}</span>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Status Verifikasi Akun</span>
                  <span className="inline-flex items-center gap-1 text-emerald-700 font-bold text-xs mt-1">
                    <CheckCircle2 className="w-4 h-4" /> Status belum tersedia
                  </span>
                </div>

                <div className="sm:col-span-2 p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block text-[11px]">Alamat Domisili KTP</span>
                  <p className="font-medium text-slate-800 leading-relaxed mt-0.5">
                    {farmer?.alamat || 'Belum tersedia'}
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
                onClick={() => {
                  setLandFormData({
                    lokasi_deskripsi: '',
                    luas_m2: '',
                    commodity_id: commodities[0]?.id || '',
                    alamat_lahan: '',
                    status_kepemilikan: 'MILIK',
                    latitude: null,
                    longitude: null,
                    foto_lahan_url: '',
                    dokumen_sertifikat_url: '',
                  });
                  setShowAddLandModal(true);
                }}
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
                    onClick={() => land.foto_lahan_url && setViewerPhoto({
                      isOpen: true,
                      title: `Foto Lahan: ${land.lokasi_deskripsi || 'Lahan Pertanian'}`,
                      url: land.foto_lahan_url,
                      description: `Luas: ${land.luas_m2} m² | Alamat: ${land.alamat_lahan || 'Belum tersedia'}`
                    })}
                    className={`relative aspect-16/10 bg-slate-100 overflow-hidden group ${land.foto_lahan_url ? 'cursor-pointer' : ''}`}
                  >
                    {land.foto_lahan_url ? (
                      <img
                        src={land.foto_lahan_url}
                        alt={land.lokasi_deskripsi || 'Foto lahan'}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-xs text-slate-500">Foto lahan belum tersedia</div>
                    )}
                    <div className="absolute top-2 left-2 px-2.5 py-0.5 rounded-full bg-black/60 text-white text-[10px] font-bold backdrop-blur-xs">
                      {land.commodity?.nama_komoditas || 'Belum tersedia'}
                    </div>
                    <div className="absolute top-2 right-2 px-2.5 py-0.5 rounded-full bg-emerald-600 text-white text-[10px] font-bold shadow-xs">
                      {land.status_kepemilikan || 'Status belum tersedia'}
                    </div>
                    <div className="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-xs font-bold gap-1">
                      <Eye className="w-4 h-4" /> Lihat Foto
                    </div>
                  </div>

                  {/* Details */}
                  <div className="p-4 flex-1 flex flex-col justify-between space-y-3 text-xs">
                    <div>
                      <h4 className="font-bold text-slate-900 text-sm">
                        {land.lokasi_deskripsi || 'Lokasi belum tersedia'}
                      </h4>
                      <div className="mt-2 space-y-1 text-slate-600">
                        <div className="flex justify-between">
                          <span className="text-slate-400">Luas Lahan:</span>
                          <strong className="text-slate-800">{Number(land.luas_m2).toLocaleString('id-ID')} m²</strong>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Komoditas:</span>
                          <span className="font-semibold text-emerald-700">{land.commodity?.nama_komoditas || 'Belum tersedia'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Status verifikasi:</span>
                          <span className="font-medium text-slate-700">{land.status_verifikasi || 'BELUM_DIVERIFIKASI'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-400">Kepemilikan:</span>
                          <span className="font-medium text-slate-700">{land.status_kepemilikan || 'Belum tersedia'}</span>
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
                        onClick={() => {
                          setSelectedLandDetail(land);
                          setLandPhotoDraft(land.foto_lahan_url || '');
                          setCertificateDraft(land.dokumen_sertifikat_url || '');
                          setIsEditingLandDocuments(false);
                        }}
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
                      {l.lokasi_deskripsi || 'Lokasi belum tersedia'} — {l.luas_m2} m² ({l.commodity?.nama_komoditas || 'Belum tersedia'})
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
                    min="25"
                    max="1000"
                    step="25"
                    placeholder="Contoh: 100 (kelipatan 25 kg)"
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
                  onChange={(latitude, longitude) => setFormData((data) => ({ ...data, latitude, longitude }))}
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
                  const isNeedsRevision = app.status === 'PERLU_PERBAIKAN_BERKAS';
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
                            <span>Lahan: {app.land?.lokasi_deskripsi || app.land?.alamat_lahan || 'Belum tersedia'}</span>
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

                      {['DISETUJUI', 'DIJADWALKAN_DISTRIBUSI', 'TERSALURKAN', 'DITOLAK_LAPANGAN'].includes(app.status) && (
                        <div className="text-xs p-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-800">
                          <strong className="font-bold">Keputusan Akhir Admin: </strong>
                          <span>{app.status === 'DITOLAK_LAPANGAN' ? 'DITOLAK' : 'DISETUJUI'}</span>
                          <p className="mt-1">
                            Jumlah pupuk diajukan: <strong>{app.jumlah_diajukan} {app.fertilizer?.satuan || 'kg'}</strong>
                          </p>
                          <p className="mt-1">
                            Jumlah pupuk disetujui: <strong>{app.jumlah_disetujui != null ? `${app.jumlah_disetujui} ${app.fertilizer?.satuan || 'kg'}` : 'Belum tersedia'}</strong>
                          </p>
                          {app.catatan_final_admin && (
                            <p className="mt-1">Catatan/alasan: {app.catatan_final_admin}</p>
                          )}
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
                    <span className="font-bold text-slate-700">{ureaUsagePercent}%</span>
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
                    <span className="font-bold text-slate-700">{npkUsagePercent}%</span>
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
                      {allocations.length === 0 && (
                        <p className="text-xs text-slate-500">Belum ada alokasi pupuk yang tersedia dari pengajuan Anda.</p>
                      )}
                      {allocations.map((alloc) => (
                        <div
                          key={alloc.id}
                          className="p-5 rounded-2xl border-2 border-slate-200 hover:border-emerald-500 bg-white hover:bg-emerald-50/20 transition-all cursor-pointer shadow-xs hover:shadow-md flex flex-col justify-between gap-4 group"
                          onClick={() => {
                            setSelectedAllocation(alloc);
                            setCurrentGps(null);
                            setPupukPhotoFile(null);
                            setScannerError(null);
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
                                Siap Dibuka
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
                          Ambil lokasi perangkat
                        </h3>
                        <p className="text-xs text-slate-500 mt-0.5">
                          Lokasi GPS aktual dikirim ke server, yang memvalidasi geofence lahan.
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
                          {currentGps
                            ? `${currentGps.latitude}, ${currentGps.longitude}`
                            : 'Belum diambil'}
                        </strong>
                        <span className="text-[11px] text-slate-500 block">
                          {currentGps ? `Akurasi ±${currentGps.accuracy}m` : 'Tekan tombol untuk mengambil GPS'}
                        </span>
                      </div>
                    </div>

                    <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between text-xs">
                      <span className="text-slate-600 font-medium">Jarak dari titik lahan terdaftar:</span>
                      <span className="font-mono font-black text-sm text-slate-900">
                        {displayedDistance === null ? 'Belum tersedia' : `${displayedDistance} meter`}
                      </span>
                    </div>

                    {isLocationValid && hasActiveLandCoordinates ? (
                      <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-950 flex items-start gap-3">
                        <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
                        <div className="text-xs space-y-1">
                          <strong className="font-bold text-emerald-900">✓ Lokasi GPS berhasil diambil</strong>
                          <p className="text-emerald-800">
                            Server akan memvalidasi lokasi terhadap lahan terdaftar saat pembukaan dikonfirmasi.
                          </p>
                        </div>
                      </div>
                    ) : !isLocationValid ? (
                      <div className="p-4 rounded-xl bg-amber-50 border border-amber-200 text-amber-950 flex items-start gap-3">
                        <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
                        <div className="text-xs space-y-1">
                          <strong className="font-bold text-amber-900">Lokasi GPS belum diambil</strong>
                          <p className="text-amber-800">
                            Ambil lokasi perangkat terlebih dahulu. Kesesuaian geofence tetap diperiksa oleh server.
                          </p>
                        </div>
                      </div>
                    ) : (
                      <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-950 text-xs">
                        Koordinat lahan alokasi belum tersedia. Minta Admin memperbarui lokasi lahan sebelum pemindaian.
                      </div>
                    )}

                    {/* Main Action Button */}
                    {isLocationValid && hasActiveLandCoordinates ? (
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
                    ) : !isLocationValid ? (
                      <button
                        onClick={requestRealGps}
                        disabled={gpsLoading}
                        className="w-full py-3.5 rounded-2xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white font-black text-sm shadow-lg shadow-emerald-600/30 transition-all flex items-center justify-center gap-2 cursor-pointer"
                      >
                        <RefreshCw className="w-4 h-4" />
                        <span>{gpsLoading ? 'Mengambil GPS...' : '[ Ambil Lokasi GPS ]'}</span>
                      </button>
                    ) : (
                      <button
                        type="button"
                        disabled
                        className="w-full py-3.5 rounded-2xl bg-slate-300 text-slate-600 font-black text-sm cursor-not-allowed"
                      >
                        Koordinat lahan belum tersedia
                      </button>
                    )}
                    {gpsError && <p role="alert" className="text-xs text-rose-700">{gpsError}</p>}

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
                    <div
                      id="petani-qr-reader"
                      className="w-full max-w-sm min-h-64 mx-auto overflow-hidden rounded-xl bg-black"
                    />
                    {scannerError && (
                      <p role="alert" className="text-xs text-rose-300">{scannerError}</p>
                    )}

                    <p className="text-xs text-slate-300 font-medium">
                      Arahkan kamera ke QR Code yang terdapat pada karung pupuk.
                    </p>

                    {scannerError && (
                      <button
                        type="button"
                        onClick={() => {
                          setScannerError(null);
                          setIsScannerActive(true);
                        }}
                        className="px-4 py-2 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-900 font-bold text-xs"
                      >
                        Coba buka kamera lagi
                      </button>
                    )}
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
                            <strong className="text-slate-900">{farmer?.nama || user?.nama || 'Belum tersedia'}</strong>
                          </div>
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Jenis Alokasi:</span>
                            <strong className="text-slate-900">{selectedAllocation?.jenis_pupuk || 'Belum tersedia'}</strong>
                          </div>
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Berat Alokasi:</span>
                            <strong className="text-slate-900">{selectedAllocation?.jumlah_kg ?? 'Belum tersedia'}{selectedAllocation?.jumlah_kg != null ? ' kg' : ''}</strong>
                          </div>
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Lahan Terdaftar:</span>
                            <strong className="text-slate-900">{selectedAllocation?.nama_lahan || targetLand?.lokasi_deskripsi || 'Belum tersedia'}</strong>
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
                            {isLocationValid ? '✓ GPS Terdeteksi' : '✕ GPS Belum Diambil'}
                          </span>
                        </div>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">GPS HP Petani:</span>
                            <strong className="font-mono text-slate-900">
                              {currentGps ? `${currentGps.latitude}, ${currentGps.longitude}` : 'Belum diambil'}
                            </strong>
                          </div>
                          <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                            <span className="text-slate-400 block text-[10px]">Koordinat Lahan Terdaftar:</span>
                            <strong className="font-mono text-slate-900">{formatCoord(activeAllocLat)}, {formatCoord(activeAllocLon)}</strong>
                          </div>
                        </div>

                        <div className="flex justify-between items-center text-xs bg-white p-2.5 rounded-xl border border-slate-200">
                          <span className="text-slate-600">Jarak dari Titik Lahan Sawah:</span>
                          <strong className="font-mono font-bold text-sm text-slate-900">
                            {displayedDistance === null ? 'Belum tersedia' : `${displayedDistance} meter`}
                          </strong>
                        </div>

                        {isLocationValid ? (
                          <p className="text-xs font-semibold text-emerald-800">
                            ✓ Lokasi tersimpan. Server akan memeriksa geofence saat konfirmasi.
                          </p>
                        ) : (
                          <div className="p-3 bg-white rounded-xl border border-rose-200 space-y-1 text-xs">
                            <strong className="text-rose-900 block font-bold">GPS belum tersedia</strong>
                            <p className="text-rose-700">
                              Ambil lokasi perangkat untuk melanjutkan. Server memutuskan apakah koordinat sesuai dengan lahan.
                            </p>
                          </div>
                        )}

                      </div>
                    </div>
                  </div>

                  <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3">
                    <div>
                      <strong className="text-sm font-bold text-slate-900">Foto karung setelah dibuka</strong>
                      <p className="text-xs text-slate-500 mt-1">
                        Ambil foto bukti dengan kamera perangkat. Foto wajib dikirim bersama lokasi.
                      </p>
                    </div>
                    <input
                      type="file"
                      accept="image/jpeg,image/png,image/webp"
                      capture="environment"
                      onChange={(event) => setPupukPhotoFile(event.target.files?.[0] || null)}
                      className="block w-full text-xs text-slate-600 file:mr-3 file:rounded-lg file:border-0 file:bg-emerald-100 file:px-3 file:py-2 file:font-bold file:text-emerald-800"
                    />
                    <p className="text-[11px] text-slate-500">Format JPG, PNG, atau WEBP; maksimum 5 MB.</p>
                    {pupukPhotoFile && (
                      <p className="text-xs text-emerald-700" role="status">
                        Foto dipilih: {pupukPhotoFile.name}
                      </p>
                    )}
                  </div>

                  {/* FINAL STATUS & CONFIRMATION BUTTON */}
                  {qrValidation.isValidQr && qrValidation.isAllocationMatch && isLocationValid && hasActiveLandCoordinates && pupukPhotoFile ? (
                    <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-4">
                      <div className="pb-3 border-b border-slate-100 flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                          <span className="text-xs font-bold text-slate-900 uppercase">
                            Status: Siap Dikonfirmasi
                          </span>
                        </div>
                        <span className="text-xs font-black px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                          SIAP DIKIRIM
                        </span>
                      </div>

                      <div className="grid grid-cols-2 gap-2 text-xs text-slate-600 bg-slate-50 p-3 rounded-xl font-medium">
                        <div>✓ QR Pupuk Valid</div>
                        <div>✓ Pupuk Sesuai Alokasi</div>
                        <div>✓ Petani Terverifikasi</div>
                        <div>✓ GPS & foto siap dikirim</div>
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
                          ? 'Ambil lokasi GPS perangkat sebelum melanjutkan.'
                          : !hasActiveLandCoordinates
                            ? 'Koordinat lahan alokasi belum tersedia. Minta Admin memperbarui lokasi lahan.'
                          : !pupukPhotoFile
                            ? 'Ambil atau pilih foto karung yang sudah dibuka sebelum mengonfirmasi.'
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
                <strong className="font-mono text-slate-900 font-bold">{selectedHistoryDetail.id_pupuk || 'Belum tersedia'}</strong>
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
                <strong className="text-slate-900">{selectedHistoryDetail.nama_petani || farmer?.nama || user?.nama || 'Belum tersedia'}</strong>
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

            <section className="space-y-3 rounded-xl border border-slate-200 p-4">
              <div className="flex items-center justify-between gap-2">
                <h4 className="text-xs font-bold uppercase tracking-wide text-slate-700">
                  Foto Lahan dan Sertifikat
                </h4>
                {!isEditingLandDocuments && (
                  <button
                    type="button"
                    onClick={() => {
                      setLandPhotoDraft(selectedLandDetail.foto_lahan_url || '');
                      setCertificateDraft(selectedLandDetail.dokumen_sertifikat_url || '');
                      setIsEditingLandDocuments(true);
                    }}
                    className="text-xs font-bold text-emerald-700 hover:text-emerald-800 underline cursor-pointer"
                  >
                    Ubah Dokumen
                  </button>
                )}
              </div>
              {isEditingLandDocuments ? (
                <>
                  <FileUploadZone
                    label="Foto Kondisi Lahan"
                    category="lahan"
                    initialUrl={landPhotoDraft || null}
                    onUploadSuccess={(url) => setLandPhotoDraft(url || '')}
                  />
                  <FileUploadZone
                    label="Sertifikat / SPPT (opsional)"
                    category="sertifikat"
                    initialUrl={certificateDraft || null}
                    helperText="Unggah foto JPG, PNG, atau WEBP (maksimal 5MB)"
                    onUploadSuccess={(url) => setCertificateDraft(url || '')}
                  />
                  <div className="flex justify-end gap-2">
                    <button
                      type="button"
                      onClick={() => setIsEditingLandDocuments(false)}
                      disabled={isSavingLandDocuments}
                      className="rounded-lg bg-slate-100 px-3 py-2 text-xs font-bold text-slate-700 disabled:opacity-50"
                    >
                      Batal
                    </button>
                    <button
                      type="button"
                      onClick={handleSaveLandDocuments}
                      disabled={isSavingLandDocuments || !landPhotoDraft}
                      className="rounded-lg bg-emerald-600 px-3 py-2 text-xs font-bold text-white disabled:opacity-50"
                    >
                      {isSavingLandDocuments ? 'Menyimpan...' : 'Simpan Dokumen'}
                    </button>
                  </div>
                </>
              ) : (
                <p className="text-xs text-slate-600">
                  Sertifikat: {selectedLandDetail.dokumen_sertifikat_url
                    ? selectedLandDetail.dokumen_sertifikat_url.split('/').pop()
                    : 'Belum diunggah'}
                </p>
              )}
              <p className="text-[11px] text-slate-500">
                Pengajuan yang masih menunggu verifikasi akan dikirim ulang ke Admin untuk ditinjau.
              </p>
            </section>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-400 block text-[11px]">Luas Lahan:</span>
                <strong className="text-slate-900 font-bold text-sm">{selectedLandDetail.luas_m2} m²</strong>
              </div>
              <div className="p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-400 block text-[11px]">Komoditas:</span>
                <strong className="text-emerald-700 font-bold text-sm">{selectedLandDetail.commodity?.nama_komoditas || 'Belum tersedia'}</strong>
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
                  placeholder="Masukkan lokasi lahan"
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
                    Jenis Komoditas <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={landFormData.commodity_id}
                    onChange={(e) => setLandFormData({ ...landFormData, commodity_id: e.target.value })}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                    required
                  >
                    <option value="">-- Pilih Komoditas --</option>
                    {commodities.map((c) => (
                      <option key={c.id} value={c.id}>{c.nama_komoditas}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Status Kepemilikan <span className="text-rose-500">*</span>
                </label>
                <select
                  value={landFormData.status_kepemilikan}
                  onChange={(e) => setLandFormData({ ...landFormData, status_kepemilikan: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-300 text-xs bg-white text-slate-800 focus:border-emerald-500 outline-hidden font-medium"
                  required
                >
                  <option value="MILIK">Milik sendiri</option>
                  <option value="GARAP">Garap</option>
                  <option value="SEWA">Sewa</option>
                </select>
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

              <FileUploadZone
                label="Foto Kondisi Lahan"
                category="lahan"
                required
                onUploadSuccess={(url) => setLandFormData((data) => ({ ...data, foto_lahan_url: url || '' }))}
              />
              <FileUploadZone
                label="Sertifikat / SPPT (opsional)"
                category="sertifikat"
                helperText="Unggah foto JPG, PNG, atau WEBP (maksimal 5MB)"
                onUploadSuccess={(url) => setLandFormData((data) => ({ ...data, dokumen_sertifikat_url: url || '' }))}
              />

              {/* Map Coordinates Picker for new Land */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Titik Koordinat GPS Lahan
                </label>
                <MapPicker
                  latitude={landFormData.latitude}
                  longitude={landFormData.longitude}
                  onChange={(latitude, longitude) => setLandFormData((data) => ({ ...data, latitude, longitude }))}
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
                      {l.lokasi_deskripsi || 'Lokasi belum tersedia'} — {l.luas_m2} m² ({l.commodity?.nama_komoditas || 'Belum tersedia'})
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
                    min="25"
                    max="1000"
                    step="25"
                    placeholder="Contoh: 100 (kelipatan 25 kg)"
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
                  onChange={(latitude, longitude) => setFormData((data) => ({ ...data, latitude, longitude }))}
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
