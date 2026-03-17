'use client';

import { useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { EyeOff, ShieldX } from 'lucide-react';
import { Sidebar } from '@/components/layout/sidebar';
import { Topbar } from '@/components/layout/topbar';
import { MobileNav } from '@/components/layout/mobile-nav';
import { ImpersonationBanner } from '@/components/layout/impersonation-banner';
import { ToastContainer } from '@/components/ui';
import { useUIStore } from '@/lib/stores/ui-store';
import { useImpersonationStore } from '@/lib/stores/impersonation-store';
import { useCurrentBusiness } from '@/lib/hooks/use-business';
import { useRealtime } from '@/lib/hooks/use-realtime';
import { requestNotificationPermission } from '@/lib/utils/browser-notification';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const { sidebarOpen, setSidebarOpen } = useUIStore();
  const { isImpersonating } = useImpersonationStore();
  const { data: business } = useCurrentBusiness();
  const isBusinessSuspended = business?.status === 'suspended';
  const isBusinessInactive = business?.status === 'inactive';
  const isBusinessHidden = isBusinessSuspended;

  // Real-time updates via NATS WebSocket
  useRealtime();

  // Request browser notification permission on first dashboard load
  useEffect(() => {
    requestNotificationPermission();
  }, []);

  // Close mobile sidebar on route change
  useEffect(() => {
    setSidebarOpen(false);
  }, [pathname, setSidebarOpen]);

  // Inactive business: block entire dashboard
  if (isBusinessInactive) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-center max-w-md mx-auto px-4">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-red-100">
            <ShieldX className="h-8 w-8 text-red-600" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Cuenta desactivada</h1>
          <p className="mt-2 text-gray-600">
            Tu cuenta ha sido desactivada por el administrador.
            Contacta a soporte para más información.
          </p>
          <a
            href="mailto:soporte@agendify.co"
            className="mt-6 inline-flex items-center gap-2 rounded-lg bg-violet-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-violet-700"
          >
            Contactar soporte
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Impersonation banner (fixed at very top) */}
      <ImpersonationBanner />

      {/* Suspended business banner */}
      {isBusinessHidden && (
        <div className={`fixed left-0 right-0 z-50 flex items-center justify-center gap-2 bg-yellow-400 px-4 py-2 text-sm font-medium text-yellow-900 ${isImpersonating ? 'top-10' : 'top-0'}`}>
          <EyeOff className="h-4 w-4" />
          Tu negocio está oculto y no aparece para usuarios. El dashboard funciona normal.
        </div>
      )}

      {/* Desktop sidebar */}
      <Sidebar />

      {/* Mobile sidebar overlay */}
      {sidebarOpen && (
        <>
          <div
            className="fixed inset-0 z-40 cursor-pointer bg-black/50 md:hidden"
            onClick={() => setSidebarOpen(false)}
          />
          <Sidebar className="!flex z-50" />
        </>
      )}

      {/* Topbar */}
      <div className={`${isImpersonating ? 'mt-10' : ''} ${isBusinessHidden ? 'mt-10' : ''}`}>
        <Topbar />
      </div>

      {/* Main content */}
      <main className={`ml-0 pb-16 md:ml-64 md:pb-0 ${
        isImpersonating && isBusinessHidden ? 'pt-[9rem]' :
        isImpersonating || isBusinessHidden ? 'pt-[6.5rem]' :
        'pt-16'
      }`}>
        <div className="px-4 py-6 md:px-6">{children}</div>
      </main>

      {/* Mobile bottom nav */}
      <MobileNav />

      {/* Toasts */}
      <ToastContainer />
    </div>
  );
}
