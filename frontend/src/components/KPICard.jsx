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
      iconBg: 'bg-emerald-50 text-emerald-500',
      badgeBg: 'bg-emerald-50 text-emerald-600 border-emerald-200/70',
    },
    blue: {
      iconBg: 'bg-blue-50 text-blue-500',
      badgeBg: 'bg-blue-50 text-blue-600 border-blue-200/70',
    },
    amber: {
      iconBg: 'bg-amber-50 text-amber-500',
      badgeBg: 'bg-amber-50 text-amber-600 border-amber-200/70',
    },
    purple: {
      iconBg: 'bg-purple-50 text-purple-500',
      badgeBg: 'bg-purple-50 text-purple-600 border-purple-200/70',
    },
    rose: {
      iconBg: 'bg-rose-50 text-rose-500',
      badgeBg: 'bg-rose-50 text-rose-600 border-rose-200/70',
    },
  };

  const style = colorStyles[color] || colorStyles.emerald;

  // Split numeric value and unit suffix if present
  const valueStr = String(value ?? '');
  const match = valueStr.match(/^(\d+(?:[.,]\d+)?)\s*([a-zA-Z%]+)?$/);
  const mainNum = match ? match[1] : valueStr;
  const unit = match && match[2] ? match[2] : null;

  return (
    <div className="p-4 rounded-2xl bg-white border border-slate-200/80 shadow-xs flex flex-col justify-between gap-2.5">
      {/* Top row: Title & Icon */}
      <div className="flex items-center justify-between gap-1.5">
        <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500 truncate">
          {title}
        </span>
        {Icon && (
          <div className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 ${style.iconBg}`}>
            <Icon className="w-4 h-4 stroke-[2.2]" />
          </div>
        )}
      </div>

      {/* Middle row: Big Value */}
      <div className="flex items-baseline my-0.5">
        <span className="text-3xl font-black tracking-tight text-slate-900 font-display">
          {mainNum}
        </span>
        {unit && (
          <span className="ml-1 text-xs font-bold text-slate-600">
            {unit}
          </span>
        )}
      </div>

      {/* Bottom row: Subtitle & Badge */}
      <div className="flex items-center justify-between gap-2 pt-0.5">
        <p className="text-[11px] text-slate-400 font-medium truncate max-w-[85px]" title={subtitle}>
          {subtitle || ''}
        </p>
        {badge && (
          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border shrink-0 ${style.badgeBg}`}>
            {badge}
          </span>
        )}
      </div>
    </div>
  );
}

