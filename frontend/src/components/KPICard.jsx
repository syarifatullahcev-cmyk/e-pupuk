import React from 'react';

export default function KPICard({
  title,
  value,
  subtitle,
  icon: Icon,
  color = 'emerald', // emerald, blue, amber, purple, rose
  badge,
}) {
  const colorStyles = {
    emerald: {
      iconBg: 'bg-emerald-50 text-emerald-600',
      badgeBg: 'bg-slate-100 text-slate-600 border-slate-200/60',
    },
    blue: {
      iconBg: 'bg-blue-50 text-blue-600',
      badgeBg: 'bg-slate-100 text-slate-600 border-slate-200/60',
    },
    amber: {
      iconBg: 'bg-amber-50 text-amber-600',
      badgeBg: 'bg-amber-50 text-amber-700 border-amber-200/60',
    },
    purple: {
      iconBg: 'bg-purple-50 text-purple-600',
      badgeBg: 'bg-purple-50 text-purple-700 border-purple-200/60',
    },
    rose: {
      iconBg: 'bg-rose-50 text-rose-600',
      badgeBg: 'bg-rose-50 text-rose-700 border-rose-200/60',
    },
  };

  const style = colorStyles[color] || colorStyles.emerald;

  // Split numeric value and unit suffix if present (e.g. "430 kg" -> "430" and "kg")
  const valueStr = String(value ?? '');
  const match = valueStr.match(/^(\d+(?:[.,]\d+)?)\s*([a-zA-Z%]+)?$/);
  const mainNum = match ? match[1] : valueStr;
  const unit = match && match[2] ? match[2] : null;

  return (
    <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs hover:shadow-md transition-all duration-200 flex flex-col justify-between gap-3">
      {/* Top row: Title & Icon */}
      <div className="flex items-center justify-between gap-2">
        <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
          {title}
        </span>
        {Icon && (
          <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${style.iconBg}`}>
            <Icon className="w-5 h-5 stroke-[2.2]" />
          </div>
        )}
      </div>

      {/* Middle row: Big Value */}
      <div className="flex items-baseline">
        <span className="text-3xl font-black tracking-tight text-slate-900">
          {mainNum}
        </span>
        {unit && (
          <span className="ml-1 text-sm font-bold text-slate-700">
            {unit}
          </span>
        )}
      </div>

      {/* Bottom row: Subtitle & Badge */}
      <div className="flex items-center justify-between gap-2 pt-1">
        <p className="text-xs text-slate-400 font-medium truncate">
          {subtitle || ''}
        </p>
        {badge && (
          <span className={`text-[10px] font-semibold px-2 py-0.5 rounded border shrink-0 ${style.badgeBg}`}>
            {badge}
          </span>
        )}
      </div>
    </div>
  );
}

