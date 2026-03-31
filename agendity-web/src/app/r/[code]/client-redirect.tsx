'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export function ClientRedirect({ code }: { code: string }) {
  const router = useRouter();

  useEffect(() => {
    // Save ref to localStorage before redirecting
    localStorage.setItem('agendity_ref_code', code);
    router.replace(`/?ref=${code}`);
  }, [code, router]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="text-center">
        <div className="text-xl font-bold text-violet-600">Agendity</div>
        <p className="mt-2 text-sm text-gray-500">Redirigiendo...</p>
      </div>
    </div>
  );
}
