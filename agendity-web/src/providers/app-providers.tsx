// ============================================================
// Agendity — App providers (React Query)
// ============================================================

'use client';

import { useState, useEffect, type ReactNode } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { isDemoMode } from '@/lib/demo/is-demo';

interface AppProvidersProps {
  children: ReactNode;
}

export default function AppProviders({ children }: AppProvidersProps) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 5 * 60 * 1000, // 5 minutes
            gcTime: 10 * 60 * 1000, // 10 minutes
            retry: 1,
            refetchOnWindowFocus: false,
          },
        },
      }),
  );

  const [demoReady, setDemoReady] = useState(false);

  useEffect(() => {
    if (!isDemoMode()) {
      setDemoReady(true);
      return;
    }

    // Dynamic import — demo code only loads when NEXT_PUBLIC_DEMO_MODE=true
    Promise.all([
      import('@/lib/demo/index').then((m) => m.setupDemoMode()),
      import('@/lib/demo/nats-mock').then((m) => m.startNatsMock()),
    ]).then(() => {
      setDemoReady(true);
    });
  }, []);

  // Wait for demo setup before rendering to avoid flicker / auth redirects
  if (!demoReady) {
    return null;
  }

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}
