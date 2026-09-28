import React from 'react';
import { Check, Clock, AlertTriangle, X, ShieldCheck, UserCheck, MapPin, Award, PackageCheck } from 'lucide-react';

const STAGES = [
  { id: 1, name: 'Pengajuan', icon: Clock },
  { id: 2, name: 'Verifikasi Berkas', icon: ShieldCheck },
  { id: 3, name: 'Penugasan PPL', icon: UserCheck },
  { id: 4, name: 'Survei Lapangan', icon: MapPin },
  { id: 5, name: 'Persetujuan Admin', icon: Award },
  { id: 6, name: 'Penggunaan Pupuk', icon: PackageCheck },
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
    <div className="w-full pt-2 pb-2">
      <div className="flex items-start">
        {STAGES.map((stage) => {
          const isDone = currentStage > stage.id;
          const isActive = currentStage === stage.id;
          const isThisStageRejected = isRejected && rejectStage === stage.id;
          const isThisStageWarning = isWarning && stage.id === 2;

          let circleBg = 'bg-white border-2 border-slate-300 text-slate-400';
          let lineBg = 'bg-slate-200';

          if (isDone) {
            circleBg = 'bg-emerald-600 text-white shadow-xs';
            lineBg = 'bg-emerald-500';
          } else if (isThisStageRejected) {
            circleBg = 'bg-rose-600 text-white shadow-xs ring-2 ring-rose-100';
            lineBg = 'bg-rose-500';
          } else if (isThisStageWarning) {
            circleBg = 'bg-amber-500 text-white shadow-xs ring-2 ring-amber-100 animate-pulse';
            lineBg = 'bg-amber-500';
          } else if (isActive) {
            circleBg = 'bg-blue-600 text-white shadow-xs ring-4 ring-blue-100';
            lineBg = 'bg-emerald-500';
          }

          // Format label into two lines if it contains space for neat vertical centering
          const words = stage.name.split(' ');
          const line1 = words[0];
          const line2 = words.slice(1).join(' ');

          return (
            <div key={stage.id} className="flex-1 flex flex-col min-w-0">
              {/* Top: Track Line leading to Circle Checkpoint */}
              <div className="flex items-center h-8">
                <div className={`flex-1 h-[2.5px] transition-colors duration-500 ${lineBg}`} />
                <div
                  className={`w-7 h-7 sm:w-8 sm:h-8 rounded-full flex items-center justify-center font-bold text-xs transition-all duration-300 shrink-0 ${circleBg}`}
                >
                  {isDone ? (
                    <Check className="w-4 h-4 stroke-[3]" />
                  ) : isThisStageRejected ? (
                    <X className="w-4 h-4 stroke-[3]" />
                  ) : isThisStageWarning ? (
                    <AlertTriangle className="w-4 h-4 stroke-[2.5]" />
                  ) : isActive && stage.id === 6 ? (
                    <PackageCheck className="w-4 h-4" />
                  ) : (
                    <stage.icon className="w-4 h-4" />
                  )}
                </div>
              </div>

              {/* Bottom: Label placed under the line segment to the left of the circle */}
              <div className="pr-5 sm:pr-8 text-center mt-2 min-h-[32px] flex flex-col justify-start items-center">
                <span
                  className={`text-[11px] sm:text-xs font-medium leading-tight block ${
                    isThisStageRejected
                      ? 'text-rose-600 font-bold'
                      : isThisStageWarning
                      ? 'text-amber-600 font-bold'
                      : isActive && stage.id === 6
                      ? 'text-blue-600 font-bold'
                      : isDone
                      ? 'text-slate-800'
                      : 'text-slate-400'
                  }`}
                >
                  {line1}
                  {line2 && <span className="block mt-0.5">{line2}</span>}
                </span>
              </div>
            </div>
          );
        })}

        {/* Trailing end tail after step 6 */}
        <div className="flex flex-col shrink-0">
          <div className="flex items-center h-8">
            <div className={`w-3 sm:w-5 h-[2.5px] ${currentStage >= 6 ? 'bg-emerald-500' : 'bg-slate-200'}`} />
          </div>
          <div className="min-h-[32px] mt-2" />
        </div>
      </div>
    </div>
  );
}
