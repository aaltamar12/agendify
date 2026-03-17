'use client';

import { Eye, X } from 'lucide-react';
import { useImpersonationStore } from '@/lib/stores/impersonation-store';
import { useStopImpersonation } from '@/lib/hooks/use-admin';

export function ImpersonationBanner() {
  const { isImpersonating, businessName } = useImpersonationStore();
  const stopImpersonation = useStopImpersonation();

  if (!isImpersonating) return null;

  return (
    <div className="flex items-center justify-center gap-3 bg-amber-400 px-4 py-2 text-sm font-medium text-amber-900 shadow-md">
      <Eye className="h-4 w-4 shrink-0" />
      <span>
        Estas observando como: <strong>{businessName}</strong>
      </span>
      <button
        onClick={stopImpersonation}
        className="ml-2 inline-flex items-center gap-1 rounded-md bg-amber-600 px-3 py-1 text-xs font-semibold text-white transition-colors hover:bg-amber-700"
      >
        <X className="h-3 w-3" />
        Salir
      </button>
    </div>
  );
}
