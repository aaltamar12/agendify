'use client';

import { AlertTriangle, Clock } from 'lucide-react';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';

export function SubscriptionBanner() {
  const { daysUntilExpiry, planLabel, isLoading } = useCurrentSubscription();

  if (isLoading || daysUntilExpiry === null || daysUntilExpiry > 5) return null;

  const isExpired = daysUntilExpiry <= 0;
  const isToday = daysUntilExpiry === 0;

  let message: string;
  let bgClass: string;
  let Icon = Clock;

  if (isExpired) {
    message = `Tu plan ${planLabel} venció hace ${Math.abs(daysUntilExpiry)} día${Math.abs(daysUntilExpiry) !== 1 ? 's' : ''}. Renueva para evitar la suspensión de tu cuenta.`;
    bgClass = 'bg-red-600 text-white';
    Icon = AlertTriangle;
  } else if (isToday) {
    message = `Tu plan ${planLabel} vence hoy. Renueva ahora para no perder acceso.`;
    bgClass = 'bg-red-500 text-white';
    Icon = AlertTriangle;
  } else {
    message = `Tu plan ${planLabel} vence en ${daysUntilExpiry} día${daysUntilExpiry !== 1 ? 's' : ''}. Renueva para mantener tus funcionalidades.`;
    bgClass = 'bg-amber-500 text-amber-950';
  }

  return (
    <div className={`flex h-10 items-center justify-center gap-2 px-4 text-sm font-medium ${bgClass}`}>
      <Icon className="h-4 w-4 shrink-0" />
      <span className="truncate">{message}</span>
    </div>
  );
}
