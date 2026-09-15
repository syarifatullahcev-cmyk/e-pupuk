import React from 'react';
import { X, ZoomIn, Download, ExternalLink, ShieldAlert } from 'lucide-react';

export default function PhotoViewerModal({
  isOpen,
  onClose,
  title = 'Pratinjau Foto',
  imageUrl,
  secondaryImageUrl,
  secondaryTitle = 'Foto Pembanding',
  description,
}) {
  if (!isOpen || !imageUrl) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-200">
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

        {/* Content Body (Single or Side-by-Side) */}
        <div className="p-6 overflow-y-auto flex-1 flex flex-col md:flex-row gap-6 items-center justify-center bg-slate-950/60">
          {/* Main Photo */}
          <div className="flex-1 flex flex-col items-center w-full">
            <div className="relative rounded-xl overflow-hidden border border-slate-800 bg-slate-900 w-full max-h-[60vh] flex items-center justify-center">
              <img
                src={imageUrl}
                alt={title}
                className="max-h-[58vh] w-auto object-contain transition-transform hover:scale-105 duration-300"
              />
            </div>
            <div className="mt-2 flex items-center gap-3">
              <span className="text-xs font-semibold text-slate-300 uppercase tracking-wider">
                {title}
              </span>
              <a
                href={imageUrl}
                target="_blank"
                rel="noreferrer"
                className="text-xs text-emerald-400 hover:text-emerald-300 flex items-center gap-1 font-medium"
              >
                Buka Tab Baru <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>

          {/* Optional Secondary Photo (for Side-by-side KTP vs Lahan verification) */}
          {secondaryImageUrl && (
            <div className="flex-1 flex flex-col items-center w-full border-t md:border-t-0 md:border-l border-slate-800 md:pl-6 pt-4 md:pt-0">
              <div className="relative rounded-xl overflow-hidden border border-slate-800 bg-slate-900 w-full max-h-[60vh] flex items-center justify-center">
                <img
                  src={secondaryImageUrl}
                  alt={secondaryTitle}
                  className="max-h-[58vh] w-auto object-contain transition-transform hover:scale-105 duration-300"
                />
              </div>
              <div className="mt-2 flex items-center gap-3">
                <span className="text-xs font-semibold text-slate-300 uppercase tracking-wider">
                  {secondaryTitle}
                </span>
                <a
                  href={secondaryImageUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="text-xs text-emerald-400 hover:text-emerald-300 flex items-center gap-1 font-medium"
                >
                  Buka Tab Baru <ExternalLink className="w-3.5 h-3.5" />
                </a>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t border-slate-800 bg-slate-900 flex items-center justify-between text-xs text-slate-400">
          <span className="flex items-center gap-1.5 text-amber-400">
            <ShieldAlert className="w-4 h-4" /> Akses dokumen ini tercatat dalam audit log sistem.
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
