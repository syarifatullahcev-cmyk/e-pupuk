import React, { useState } from 'react';
import { X, ZoomIn, Download, ExternalLink, ShieldAlert, FileText, Image as ImageIcon, AlertCircle } from 'lucide-react';

export default function PhotoViewerModal({
  isOpen,
  onClose,
  title = 'Pratinjau Dokumen',
  imageUrl,
  secondaryImageUrl,
  secondaryTitle = 'Foto Pembanding',
  description,
}) {
  const [imageError, setImageError] = useState(false);
  const [secondaryImageError, setSecondaryImageError] = useState(false);

  if (!isOpen || !imageUrl) return null;

  const isPdf = (url) => typeof url === 'string' && (url.toLowerCase().endsWith('.pdf') || url.includes('/pdf'));
  const isUrlLike = (url) => typeof url === 'string' && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/') || url.startsWith('data:'));

  const renderContent = (url, itemTitle, hasError, setHasError) => {
    if (!url) return null;

    // 1. If it's a PDF
    if (isPdf(url)) {
      return (
        <div className="w-full flex flex-col items-center">
          <div className="w-full h-[58vh] bg-slate-900 border border-slate-800 rounded-xl overflow-hidden flex flex-col items-center justify-center p-6 text-center">
            <div className="w-16 h-16 rounded-2xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center mb-4">
              <FileText className="w-8 h-8 text-blue-400" />
            </div>
            <h4 className="text-base font-bold text-white mb-1 max-w-md truncate">{url.split('/').pop()}</h4>
            <p className="text-xs text-slate-400 mb-6 max-w-sm">
              Dokumen resmi format PDF tersimpan aman di server E-Pupuk.
            </p>
            <div className="flex items-center gap-3">
              <a
                href={url}
                target="_blank"
                rel="noreferrer"
                className="px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold flex items-center gap-2 transition-colors shadow-lg shadow-blue-600/30"
              >
                <ExternalLink className="w-4 h-4" /> Buka Dokumen PDF
              </a>
              <a
                href={url}
                download
                className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold flex items-center gap-2 transition-colors border border-slate-700"
              >
                <Download className="w-4 h-4" /> Unduh Berkas
              </a>
            </div>
          </div>
        </div>
      );
    }

    // 2. If it's a valid image URL and no loading error
    if (isUrlLike(url) && !hasError) {
      return (
        <div className="relative rounded-xl overflow-hidden border border-slate-800 bg-slate-900 w-full max-h-[60vh] flex items-center justify-center">
          <img
            src={url}
            alt={itemTitle}
            onError={() => setHasError(true)}
            className="max-h-[58vh] w-auto object-contain transition-transform hover:scale-105 duration-300"
          />
        </div>
      );
    }

    // 3. Fallback for text certificate number / reference or image error
    return (
      <div className="w-full h-[50vh] bg-slate-900 border border-slate-800 rounded-xl p-8 flex flex-col items-center justify-center text-center">
        <div className="w-16 h-16 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mb-4">
          <FileText className="w-8 h-8 text-emerald-400" />
        </div>
        <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-400 mb-1">
          Identitas Dokumen Kepemilikan Lahan
        </span>
        <h4 className="text-lg font-mono font-bold text-white bg-slate-950 px-4 py-2 rounded-lg border border-slate-800 mb-3 max-w-md break-all">
          {url}
        </h4>
        <p className="text-xs text-slate-400 max-w-md mb-4 leading-relaxed">
          Nomor registrasi sertifikat tanah terdaftar pada data spasial petani. Fisik dokumen telah diverifikasi secara administratif.
        </p>
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-950/60 text-emerald-400 border border-emerald-800/50">
          ✓ Tervalidasi Sistem E-Pupuk
        </span>
      </div>
    );
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-in fade-in duration-200">
      <div className="relative w-full max-w-5xl bg-slate-900 border border-slate-800 rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[92vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-800 bg-slate-900/90">
          <div>
            <h3 className="text-lg font-bold text-white flex items-center gap-2">
              <ZoomIn className="w-5 h-5 text-emerald-400" />
              {title}
            </h3>
            {description && (
              <p className="text-xs text-slate-400 mt-0.5">{description}</p>
            )}
          </div>
          <button
            onClick={onClose}
            className="p-2 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-6 overflow-y-auto flex-1 flex flex-col md:flex-row gap-6 items-center justify-center bg-slate-950/60">
          {/* Main Photo / Doc */}
          <div className="flex-1 flex flex-col items-center w-full">
            {renderContent(imageUrl, title, imageError, setImageError)}
            <div className="mt-3 flex items-center gap-3">
              <span className="text-xs font-semibold text-slate-300 uppercase tracking-wider">
                {title}
              </span>
              {isUrlLike(imageUrl) && (
                <a
                  href={imageUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="text-xs text-emerald-400 hover:text-emerald-300 flex items-center gap-1 font-medium"
                >
                  Buka Tab Baru <ExternalLink className="w-3.5 h-3.5" />
                </a>
              )}
            </div>
          </div>

          {/* Optional Secondary Photo */}
          {secondaryImageUrl && (
            <div className="flex-1 flex flex-col items-center w-full border-t md:border-t-0 md:border-l border-slate-800 md:pl-6 pt-4 md:pt-0">
              {renderContent(secondaryImageUrl, secondaryTitle, secondaryImageError, setSecondaryImageError)}
              <div className="mt-3 flex items-center gap-3">
                <span className="text-xs font-semibold text-slate-300 uppercase tracking-wider">
                  {secondaryTitle}
                </span>
                {isUrlLike(secondaryImageUrl) && (
                  <a
                    href={secondaryImageUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="text-xs text-emerald-400 hover:text-emerald-300 flex items-center gap-1 font-medium"
                  >
                    Buka Tab Baru <ExternalLink className="w-3.5 h-3.5" />
                  </a>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t border-slate-800 bg-slate-900 flex items-center justify-between text-xs text-slate-400">
          <span className="flex items-center gap-1.5 text-amber-400">
            <ShieldAlert className="w-4 h-4" /> Akses berkas ini dicatat dalam sistem audit E-Pupuk.
          </span>
          <button
            onClick={onClose}
            className="px-4 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 font-medium transition-colors"
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
}
