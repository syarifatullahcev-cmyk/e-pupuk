import React from 'react';
import { 
  Clock, CheckCircle, AlertTriangle, XCircle, 
  MapPin, ShieldCheck, UserCheck, PackageCheck, Send
} from 'lucide-react';

export const STATUS_CONFIG = {
  DIAJUKAN: {
    label: 'Diajukan',
    bg: 'bg-slate-100 text-slate-700 border-slate-200',
    icon: Send,
  },
  MENUNGGU_VERIFIKASI_BERKAS: {
    label: 'Menunggu Verifikasi Berkas',
    bg: 'bg-amber-50 text-amber-800 border-amber-300 ring-1 ring-amber-400/20',
    icon: Clock,
  },
  PERLU_PERBAIKAN_BERKAS: {
    label: 'Perlu Perbaikan Berkas',
    bg: 'bg-orange-100 text-orange-800 border-orange-300 font-semibold animate-pulse',
    icon: AlertTriangle,
  },
  BERKAS_TERVERIFIKASI: {
    label: 'Berkas Terverifikasi',
    bg: 'bg-teal-50 text-teal-800 border-teal-300',
    icon: ShieldCheck,
  },
  DITUGASKAN_KE_PPL: {
    label: 'Ditugaskan ke PPL',
    bg: 'bg-sky-50 text-sky-800 border-sky-300',
    icon: UserCheck,
  },
  SURVEI_LAPANGAN: {
    label: 'Sedang Survei Fisik',
    bg: 'bg-indigo-50 text-indigo-800 border-indigo-300 ring-1 ring-indigo-400/20',
    icon: MapPin,
  },
  MENUNGGU_PERSETUJUAN_AKHIR: {
    label: 'Menunggu Persetujuan Akhir',
    bg: 'bg-purple-50 text-purple-800 border-purple-300',
    icon: Clock,
  },
  DISETUJUI: {
    label: 'Disetujui',
    bg: 'bg-emerald-50 text-emerald-800 border-emerald-300',
    icon: CheckCircle,
  },
  DITOLAK_BERKAS: {
    label: 'Ditolak (Berkas)',
    bg: 'bg-rose-100 text-rose-800 border-rose-300',
    icon: XCircle,
  },
  DITOLAK_LAPANGAN: {
    label: 'Ditolak (Lapangan)',
    bg: 'bg-rose-100 text-rose-800 border-rose-300',
    icon: XCircle,
  },
  DIJADWALKAN_DISTRIBUSI: {
    label: 'Siap Diambil (QR Terbit)',
    bg: 'bg-emerald-100 text-emerald-900 border-emerald-400 font-semibold ring-2 ring-emerald-500/20',
    icon: PackageCheck,
  },
  TERSALURKAN: {
    label: 'Telah Disalurkan',
    bg: 'bg-emerald-600 text-white border-transparent',
    icon: CheckCircle,
  },
};

export default function StatusBadge({ status, className = '' }) {
  const config = STATUS_CONFIG[status] || {
    label: status || 'Tidak Diketahui',
    bg: 'bg-gray-100 text-gray-700 border-gray-300',
    icon: Clock,
  };

  const IconComponent = config.icon;

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border shadow-xs transition-colors ${config.bg} ${className}`}
    >
      <IconComponent className="w-3.5 h-3.5 shrink-0" />
      <span>{config.label}</span>
    </span>
  );
}
