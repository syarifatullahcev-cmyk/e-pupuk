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
      bg: 'from-emerald-50 to-white',
      border: 'border-emerald-200',
      iconBg: 'bg-emerald-100 text-emerald-700',
      valueText: 'text-emerald-950',
    },
    blue: {
      bg: 'from-sky-50 to-white',
      border: 'border-sky-200',
      iconBg: 'bg-sky-100 text-sky-700',
      valueText: 'text-sky-950',
    },
    amber: {
      bg: 'from-amber-50 to-white',
      border: 'border-amber-200',
      iconBg: 'bg-amber-100 text-amber-700',
      valueText: 'text-amber-950',
    },
    purple: {
      bg: 'from-purple-50 to-white',
      border: 'border-purple-200',
      iconBg: 'bg-purple-100 text-purple-700',
      valueText: 'text-purple-950',
    },
    rose: {
      bg: 'from-rose-50 to-white',
      border: 'border-rose-200',
      iconBg: 'bg-rose-100 text-rose-700',
      valueText: 'text-rose-950',
    },
  };

  const style = colorStyles[color] || colorStyles.emerald;

  return (
    <div
      className={`p-5 rounded-2xl bg-gradient-to-br ${style.bg} border ${style.border} shadow-sm hover:shadow-md transition-all duration-300 flex flex-col justify-between`}
    >
      <div className="flex items-center justify-between gap-3">
        <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
          {title}
        </span>
        {Icon && (
          <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${style.iconBg} shrink-0`}>
            <Icon className="w-5 h-5" />
          </div>
        )}
      </div>

      <div className="mt-3 flex items-baseline justify-between gap-2">
        <span className={`text-2xl lg:text-3xl font-extrabold tracking-tight ${style.valueText}`}>
          {value}
        </span>
        {badge && (
          <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-white/80 border border-slate-200 text-slate-600">
            {badge}
          </span>
        )}
      </div>

      {subtitle && (
        <p className="mt-2 text-xs text-slate-500 font-medium">
          {subtitle}
        </p>
      )}
    </div>
  );
}
