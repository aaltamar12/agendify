'use client';

import { ArrowRight } from 'lucide-react';
import Link from 'next/link';

interface UpgradeBannerProps {
  /** The feature name that is restricted */
  feature?: string;
  /** Custom message override */
  message?: string;
  /** Target plan to recommend */
  targetPlan?: string;
  className?: string;
}

/**
 * A banner shown on pages restricted by the current plan.
 * Displays a violet gradient CTA to upgrade.
 */
export function UpgradeBanner({
  feature,
  message,
  targetPlan = 'Profesional',
  className = '',
}: UpgradeBannerProps) {
  const displayMessage =
    message ??
    (feature
      ? `Mejora tu plan para acceder a ${feature}`
      : 'Mejora tu plan para acceder a esta función');

  return (
    <div
      className={`relative overflow-hidden rounded-xl bg-gradient-to-r from-violet-600 to-violet-500 p-4 sm:p-5 ${className}`}
    >
      {/* Decorative background circle */}
      <div className="absolute -right-8 -top-8 h-32 w-32 rounded-full bg-white/10" />
      <div className="absolute -bottom-4 -left-4 h-20 w-20 rounded-full bg-white/5" />

      <div className="relative flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm font-medium text-white/90">{displayMessage}</p>
          <p className="mt-0.5 text-xs text-white/70">
            Desbloquea todas las funciones con el Plan {targetPlan}
          </p>
        </div>
        <Link
          href="/dashboard/settings?tab=plan"
          className="inline-flex items-center gap-2 whitespace-nowrap rounded-lg bg-white px-4 py-2 text-sm font-medium text-violet-700 shadow-sm transition-colors hover:bg-violet-50"
        >
          Ver planes
          <ArrowRight className="h-4 w-4" />
        </Link>
      </div>
    </div>
  );
}
