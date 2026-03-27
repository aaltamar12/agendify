'use client';

import Link from 'next/link';
import { AlertTriangle, Clock, Info } from 'lucide-react';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';

export function SubscriptionBanner() {
  const { daysUntilExpiry, planLabel, isTrialing, isLoading } = useCurrentSubscription();

  if (isLoading || daysUntilExpiry === null) return null;

  // Trial informative banner: show for all trialing businesses with more than 5 days remaining
  const showTrialInfo = isTrialing && daysUntilExpiry > 5;
  // Urgency banner: ≤5 days or expired
  const showUrgency = daysUntilExpiry <= 5;

  if (!showTrialInfo && !showUrgency) return null;

  let message: string;
  let bgClass: string;
  let Icon = Clock;
  let ctaLabel = 'Ver planes';

  if (showTrialInfo) {
    message = `Estás en tu periodo de prueba. Te quedan ${daysUntilExpiry} día${daysUntilExpiry !== 1 ? 's' : ''}.`;
    bgClass = 'bg-blue-500 text-white';
    Icon = Info;
  } else if (daysUntilExpiry <= 0) {
    const absDays = Math.abs(daysUntilExpiry);
    message = `Tu plan ${planLabel} venció hace ${absDays} día${absDays !== 1 ? 's' : ''}. Tu negocio no aparece para usuarios hasta que renueves.`;
    bgClass = 'bg-red-600 text-white';
    Icon = AlertTriangle;
    ctaLabel = 'Renovar';
  } else if (daysUntilExpiry === 0) {
    message = `Tu plan ${planLabel} vence hoy. Renueva ahora para no perder acceso.`;
    bgClass = 'bg-red-500 text-white';
    Icon = AlertTriangle;
    ctaLabel = 'Renovar';
  } else {
    message = `Tu plan ${planLabel} vence en ${daysUntilExpiry} día${daysUntilExpiry !== 1 ? 's' : ''}. Renueva para mantener tus funcionalidades.`;
    bgClass = 'bg-amber-500 text-amber-950';
    ctaLabel = 'Renovar';
  }

  return (
    <Link href="/dashboard/subscription/checkout" className={`flex h-10 items-center justify-center gap-2 px-4 text-sm font-medium ${bgClass} hover:opacity-90 transition-opacity`}>
      <Icon className="h-4 w-4 shrink-0" />
      <span className="truncate">{message}</span>
      <span className="shrink-0 rounded bg-white/20 px-2 py-0.5 text-xs font-bold">{ctaLabel}</span>
    </Link>
  );
}
