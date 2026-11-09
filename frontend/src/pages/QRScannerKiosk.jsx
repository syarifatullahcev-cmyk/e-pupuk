import React, { useRef, useState } from 'react';
import {
  QrCode, CheckCircle2, AlertTriangle, XCircle, ArrowLeft,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { distributionsApi, filesApi } from '../services/api';

export default function QRScannerKiosk() {
  const [tokenInput, setTokenInput] = useState('');
  const [fertilizerPhoto, setFertilizerPhoto] = useState(null);
  const [loading, setLoading] = useState(false);
  const [scanResult, setScanResult] = useState(null);
  const photoInputRef = useRef(null);

  const getCurrentPosition = () => new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Browser ini tidak mendukung GPS.'));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      ({ coords }) => resolve({
        latitude: coords.latitude,
        longitude: coords.longitude,
      }),
      (error) => {
        const messages = {
          1: 'Izin lokasi ditolak. Aktifkan izin lokasi untuk melanjutkan.',
          2: 'Lokasi tidak tersedia. Periksa GPS atau jaringan perangkat.',
          3: 'Permintaan lokasi melewati batas waktu. Coba lagi di area terbuka.',
        };
        reject(new Error(messages[error.code] || 'Lokasi perangkat gagal dibaca.'));
      },
      { enableHighAccuracy: true, maximumAge: 0, timeout: 20000 },
    );
  });

  const handleScanOrSubmit = async () => {
    const code = tokenInput.trim();
    if (!code) {
      setScanResult({ success: false, status: 'ERROR', message: 'Masukkan token QR yang ditampilkan pada pengajuan Anda.' });
      return;
    }
    if (!fertilizerPhoto) {
      setScanResult({ success: false, status: 'ERROR', message: 'Ambil foto karung pupuk terlebih dahulu.' });
      return;
    }

    setLoading(true);
    setScanResult(null);

    try {
      const location = await getCurrentPosition();
      const uploadedPhoto = await filesApi.upload(fertilizerPhoto, 'pupuk');
      const res = await distributionsApi.scanQr({
        qr_token: code,
        ...location,
        foto_pupuk_url: uploadedPhoto.data.url,
      });
      setScanResult(res.data);
    } catch (err) {
      setScanResult({
        success: false,
        status: 'ERROR',
        message: err.response?.data?.detail || 'Terjadi kesalahan saat memvalidasi QR.',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 text-white p-4 sm:p-8 flex flex-col justify-between">
      <div className="max-w-2xl mx-auto w-full space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between pb-4 border-b border-slate-800">
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-xs font-semibold text-slate-400 hover:text-white transition-colors"
          >
            <ArrowLeft className="w-4 h-4" /> Kembali ke Dashboard
          </Link>
          <span className="text-xs font-bold uppercase tracking-wider text-emerald-400 bg-emerald-950/60 px-3 py-1 rounded-full border border-emerald-800">
            Validasi Pengambilan Pupuk
          </span>
        </div>

        <div className="text-center space-y-2">
          <div className="w-16 h-16 rounded-3xl bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center mx-auto shadow-lg shadow-emerald-900/40">
            <QrCode className="w-8 h-8" />
          </div>
          <h1 className="text-2xl sm:text-3xl font-black font-display text-white">
            Validasi QR di Lokasi Lahan
          </h1>
          <p className="text-xs text-slate-400 max-w-md mx-auto">
            Halaman ini mengikuti API saat ini: perlu login sebagai petani pemilik QR, GPS aktif, dan foto karung pupuk. Pemindaian kamera kios dengan akun khusus belum didukung.
          </p>
        </div>

        {/* Input Card */}
        <div className="bg-slate-950 rounded-3xl p-6 border border-slate-800 shadow-xl space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              Masukkan Kode QR / Token Penyaluran:
            </label>
            <div className="flex gap-2">
              <input
                type="text"
                value={tokenInput}
                onChange={(e) => setTokenInput(e.target.value)}
                placeholder="Masukkan token dari pengajuan Anda"
                className="flex-1 px-4 py-3 rounded-xl bg-slate-900 border border-slate-700 text-white text-xs font-mono focus:border-emerald-500 outline-hidden tracking-wider uppercase"
              />
              <button
                type="button"
                onClick={handleScanOrSubmit}
                disabled={loading}
                className="px-5 py-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 font-bold text-xs text-white transition-colors flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
              >
                {loading ? 'Memvalidasi...' : 'Verifikasi'}
              </button>
            </div>
          </div>

          <div className="pt-3 border-t border-slate-800 space-y-2">
            <label className="block text-xs font-semibold text-slate-300">
              Foto karung pupuk (wajib):
            </label>
            <input
              ref={photoInputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              capture="environment"
              onChange={(event) => setFertilizerPhoto(event.target.files?.[0] || null)}
              className="block w-full text-xs text-slate-300 file:mr-3 file:rounded-lg file:border-0 file:bg-emerald-700 file:px-3 file:py-2 file:text-xs file:font-bold file:text-white"
            />
            {fertilizerPhoto && (
              <p className="text-xs text-emerald-300">{fertilizerPhoto.name}</p>
            )}
          </div>
        </div>

        {/* Verification Result Display */}
        {scanResult && (
          <div
            className={`rounded-3xl p-6 border animate-in zoom-in-95 duration-200 ${
              scanResult.status === 'VALID'
                ? 'bg-emerald-950/40 border-emerald-600 text-emerald-200'
                : scanResult.status === 'ALREADY_CLAIMED'
                ? 'bg-amber-950/40 border-amber-600 text-amber-200'
                : 'bg-rose-950/40 border-rose-600 text-rose-200'
            }`}
          >
            <div className="flex items-start gap-4">
              <div className="shrink-0 mt-0.5">
                {scanResult.status === 'VALID' ? (
                  <CheckCircle2 className="w-8 h-8 text-emerald-400" />
                ) : scanResult.status === 'ALREADY_CLAIMED' ? (
                  <AlertTriangle className="w-8 h-8 text-amber-400" />
                ) : (
                  <XCircle className="w-8 h-8 text-rose-400" />
                )}
                <p className="text-center text-[11px] text-slate-500">
                  Validasi memerlukan koneksi internet. Jangan unggah foto simulasi atau dummy.
                </p>
              </div>

              <div className="flex-1 space-y-2">
                <div className="flex items-center gap-2">
                  <h3 className="text-lg font-black text-white">
                    {scanResult.status === 'VALID'
                      ? 'Validasi Berhasil!'
                      : scanResult.status === 'ALREADY_CLAIMED'
                      ? 'Perhatian: Sudah Diambil'
                      : 'Kode QR Tidak Valid'}
                  </h3>
                  <span className="text-xs px-2 py-0.5 rounded-full font-mono font-bold bg-white/10">
                    {scanResult.status}
                  </span>
                </div>

                <p className="text-xs leading-relaxed opacity-90">
                  {scanResult.message}
                </p>

                {scanResult.distribution && (
                  <div className="mt-4 pt-3 border-t border-white/10 grid grid-cols-2 gap-3 text-xs">
                    <div>
                      <span className="text-slate-400 block text-[10px]">Alokasi Pupuk</span>
                      <strong className="text-white font-bold text-sm">
                        {scanResult.distribution.jumlah_disalurkan} kg
                      </strong>
                    </div>
                    <div>
                      <span className="text-slate-400 block text-[10px]">Status Penyaluran</span>
                      <strong className="text-emerald-400 font-bold text-sm">
                        {scanResult.distribution.status_penyaluran}
                      </strong>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="text-center text-xs text-slate-600 pt-6">
        Sistem Distribusi Digital Pupuk Bersubsidi &copy; 2026 Dinas Pertanian Kab. Mojokerto
      </div>
    </div>
  );
}
