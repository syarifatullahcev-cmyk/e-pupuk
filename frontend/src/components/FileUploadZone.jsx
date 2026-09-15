import React, { useState, useRef } from 'react';
import { UploadCloud, CheckCircle, AlertCircle, FileImage, X } from 'lucide-react';
import { filesApi } from '../services/api';

export default function FileUploadZone({
  label = 'Unggah Foto',
  category = 'lahan', // 'ktp', 'lahan', 'survei'
  helperText = 'Format: JPG, PNG, WEBP (Maksimal 5MB)',
  initialUrl = null,
  onUploadSuccess,
  required = false,
}) {
  const [previewUrl, setPreviewUrl] = useState(initialUrl);
  const [uploading, setUploading] = useState(false);
  const [errorMsg, setErrorMsg] = useState(null);
  const fileInputRef = useRef(null);

  const handleFileChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Check size <= 5MB
    if (file.size > 5 * 1024 * 1024) {
      setErrorMsg('Ukuran file melebihi batas 5MB.');
      return;
    }

    // Check MIME type
    const validTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!validTypes.includes(file.type)) {
      setErrorMsg('Format file tidak didukung. Harap pilih gambar JPG, PNG, atau WEBP.');
      return;
    }

    setErrorMsg(null);
    setUploading(true);

    // Local preview immediately
    const localPreview = URL.createObjectURL(file);
    setPreviewUrl(localPreview);

    try {
      const res = await filesApi.upload(file, category);
      const serverUrl = res.data.url;
      setPreviewUrl(serverUrl);
      if (onUploadSuccess) {
        onUploadSuccess(serverUrl);
      }
    } catch (err) {
      setErrorMsg(err.response?.data?.detail || 'Gagal mengunggah file. Silakan coba lagi.');
    } finally {
      setUploading(false);
    }
  };

  const handleRemove = (e) => {
    e.stopPropagation();
    setPreviewUrl(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
    if (onUploadSuccess) {
      onUploadSuccess(null);
    }
  };

  return (
    <div className="w-full">
      <div className="flex items-center justify-between mb-1.5">
        <label className="block text-xs font-semibold text-slate-700">
          {label} {required && <span className="text-rose-500">*</span>}
        </label>
        {previewUrl && (
          <span className="text-xs font-semibold text-emerald-600 flex items-center gap-1">
            <CheckCircle className="w-3.5 h-3.5" /> Terunggah
          </span>
        )}
      </div>

      <div
        onClick={() => fileInputRef.current?.click()}
        className={`relative border-2 border-dashed rounded-xl p-4 text-center cursor-pointer transition-all duration-200 ${
          previewUrl
            ? 'border-emerald-300 bg-emerald-50/40 hover:bg-emerald-50/70'
            : errorMsg
            ? 'border-rose-300 bg-rose-50/30'
            : 'border-slate-300 hover:border-emerald-500 bg-slate-50/60 hover:bg-slate-50'
        }`}
      >
        <input
          type="file"
          ref={fileInputRef}
          onChange={handleFileChange}
          accept="image/jpeg,image/png,image/webp"
          className="hidden"
        />

        {previewUrl ? (
          <div className="flex items-center gap-4">
            <div className="relative w-20 h-20 rounded-lg overflow-hidden border border-emerald-200 bg-white shadow-xs shrink-0">
              <img
                src={previewUrl}
                alt="Preview"
                className="w-full h-full object-cover"
              />
            </div>
            <div className="text-left flex-1 min-w-0">
              <p className="text-xs font-semibold text-slate-800 truncate">
                Foto Berhasil Dipilih
              </p>
              <p className="text-[11px] text-slate-500 mt-0.5">
                Klik untuk mengganti foto dokumen
              </p>
              {uploading && (
                <div className="mt-1.5 flex items-center gap-1.5 text-xs text-blue-600 font-medium">
                  <div className="w-3.5 h-3.5 border-2 border-blue-600 border-t-transparent rounded-full animate-spin" />
                  Mengunggah ke server...
                </div>
              )}
            </div>
            <button
              type="button"
              onClick={handleRemove}
              className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-white transition-colors"
              title="Hapus foto"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        ) : (
          <div className="py-3 flex flex-col items-center justify-center">
            <div className="w-10 h-10 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mb-2">
              {uploading ? (
                <div className="w-5 h-5 border-2 border-emerald-600 border-t-transparent rounded-full animate-spin" />
              ) : (
                <UploadCloud className="w-5 h-5" />
              )}
            </div>
            <p className="text-xs font-semibold text-slate-700">
              {uploading ? 'Sedang mengunggah...' : 'Klik untuk pilih foto atau seret ke sini'}
            </p>
            <p className="text-[11px] text-slate-500 mt-0.5">{helperText}</p>
          </div>
        )}
      </div>

      {errorMsg && (
        <p className="mt-1.5 text-xs text-rose-600 flex items-center gap-1 font-medium">
          <AlertCircle className="w-3.5 h-3.5" /> {errorMsg}
        </p>
      )}
    </div>
  );
}
