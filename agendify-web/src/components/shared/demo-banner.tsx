// ============================================================
// Agendify — Demo mode banner (orange fixed bar)
// ============================================================

'use client';

import { useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export default function DemoBanner() {
  const queryClient = useQueryClient();

  const handleReset = useCallback(async () => {
    const { resetStore } = await import('@/lib/demo/store');
    resetStore();
    queryClient.invalidateQueries();
    window.location.reload();
  }, [queryClient]);

  return (
    <div className="flex items-center justify-center gap-3 bg-orange-500 px-4 py-2 text-sm font-semibold text-white shadow-md">
      <span className="flex items-center gap-1.5">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          className="h-4 w-4"
        >
          <path
            fillRule="evenodd"
            d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
            clipRule="evenodd"
          />
        </svg>
        MODO DEMO — Datos ficticios, sin conexión al servidor
      </span>
      <button
        onClick={handleReset}
        className="rounded bg-white/20 px-3 py-0.5 text-xs font-medium transition-colors hover:bg-white/30"
      >
        Resetear datos
      </button>
    </div>
  );
}
