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

  // In demo mode, block rendering until the adapter is installed.
  // On server, isDemoMode() returns false but NEXT_PUBLIC_DEMO_MODE is still 'true',
  // so we check the env var directly to avoid hydration mismatch where queries fire
  // before the demo adapter is ready.
  const envDemo = process.env.NEXT_PUBLIC_DEMO_MODE === 'true';
  const isDemo = isDemoMode();
  const [demoReady, setDemoReady] = useState(!envDemo);

  useEffect(() => {
    if (!isDemo) return;

    // Dynamic import — demo code only loads when NEXT_PUBLIC_DEMO_MODE=true
    Promise.all([
      import('@/lib/demo/index').then((m) => m.setupDemoMode()),
      import('@/lib/demo/nats-mock').then((m) => m.startNatsMock()),
    ]).then(() => {
      setDemoReady(true);
    });
  }, [isDemo]);

  // Only block rendering when demo mode needs async setup
  if (!demoReady) {
    return null;
  }

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}
