import React from 'react';
import { Check, Clock, AlertTriangle, X, ShieldCheck, UserCheck, MapPin, Award, PackageCheck } from 'lucide-react';

const STAGES = [
  { id: 1, name: 'Pengajuan', icon: Clock },
  { id: 2, name: 'Verifikasi Berkas', icon: ShieldCheck },
  { id: 3, name: 'Penugasan PPL', icon: UserCheck },
  { id: 4, name: 'Survei Lapangan', icon: MapPin },
  { id: 5, name: 'Persetujuan Akhir', icon: Award },
  { id: 6, name: 'Penyaluran Pupuk', icon: PackageCheck },
];

export default function ProgressStepper({ status }) {
  // Determine current active stage index (1-based)
  let currentStage = 1;
  let isWarning = false;
  let isRejected = false;
  let rejectStage = 0;

  switch (status) {
    case 'DIAJUKAN':
      currentStage = 1;
      break;
    case 'MENUNGGU_VERIFIKASI_BERKAS':
      currentStage = 2;
      break;
    case 'PERLU_PERBAIKAN_BERKAS':
      currentStage = 2;
      isWarning = true;
      break;
    case 'DITOLAK_BERKAS':
      currentStage = 2;
      isRejected = true;
      rejectStage = 2;
      break;
    case 'BERKAS_TERVERIFIKASI':
      currentStage = 3;
      break;
    case 'DITUGASKAN_KE_PPL':
      currentStage = 4;
      break;
    case 'SURVEI_LAPANGAN':
      currentStage = 4;
      break;
    case 'MENUNGGU_PERSETUJUAN_AKHIR':
      currentStage = 5;
      break;
    case 'DITOLAK_LAPANGAN':
      currentStage = 5;
      isRejected = true;
      rejectStage = 5;
      break;
    case 'DISETUJUI':
      currentStage = 6;
      break;
    case 'DIJADWALKAN_DISTRIBUSI':
      currentStage = 6;
      break;
    case 'TERSALURKAN':
      currentStage = 7; // All done
      break;
    default:
      currentStage = 1;
  }

  return (
    <div className="w-full py-4">
      <div className="flex items-center justify-between relative">
        {/* Continuous track line */}
        <div className="absolute top-1/2 left-6 right-6 -translate-y-1/2 h-1 bg-slate-200 z-0">
          <div
            className={`h-full transition-all duration-500 ${
              isRejected ? 'bg-rose-500' : isWarning ? 'bg-amber-500' : 'bg-emerald-500'
            }`}
            style={{
              width: `${Math.min(100, Math.max(0, ((currentStage - 1) / (STAGES.length - 1)) * 100))}%`,
            }}
          />
        </div>

        {STAGES.map((stage) => {
          const isDone = currentStage > stage.id;
          const isActive = currentStage === stage.id;
          const isThisStageRejected = isRejected && rejectStage === stage.id;
          const isThisStageWarning = isWarning && stage.id === 2;

          let circleBg = 'bg-white border-2 border-slate-300 text-slate-400';
          if (isDone) {
            circleBg = 'bg-emerald-600 border-2 border-emerald-600 text-white shadow-sm shadow-emerald-200';
          } else if (isThisStageRejected) {
            circleBg = 'bg-rose-600 border-2 border-rose-600 text-white shadow-sm shadow-rose-200 ring-4 ring-rose-100';
          } else if (isThisStageWarning) {
            circleBg = 'bg-amber-500 border-2 border-amber-500 text-white shadow-sm shadow-amber-200 ring-4 ring-amber-100 animate-pulse';
          } else if (isActive) {
            circleBg = 'bg-blue-600 border-2 border-blue-600 text-white shadow-md shadow-blue-200 ring-4 ring-blue-100 animate-pulse';
          }

          return (
            <div key={stage.id} className="relative z-10 flex flex-col items-center group">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm transition-all duration-300 ${circleBg}`}
              >
                {isDone ? (
                  <Check className="w-5 h-5 stroke-[2.5]" />
                ) : isThisStageRejected ? (
                  <X className="w-5 h-5 stroke-[2.5]" />
                ) : isThisStageWarning ? (
                  <AlertTriangle className="w-5 h-5 stroke-[2.5]" />
                ) : (
                  <stage.icon className="w-4 h-4" />
                )}
              </div>
              <span
                className={`mt-2 text-xs font-medium text-center max-w-[80px] leading-tight transition-colors ${
                  isThisStageRejected
                    ? 'text-rose-600 font-bold'
                    : isThisStageWarning
                    ? 'text-amber-600 font-bold'
                    : isActive
                    ? 'text-blue-700 font-bold'
                    : isDone
                    ? 'text-emerald-700 font-semibold'
                    : 'text-slate-400'
                }`}
              >
                {stage.name}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
