'use client';

import { useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { Clock, EyeOff, ShieldX, Timer } from 'lucide-react';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import { Sidebar } from '@/components/layout/sidebar';
import { Topbar } from '@/components/layout/topbar';
import { MobileNav } from '@/components/layout/mobile-nav';
import { ImpersonationBanner } from '@/components/layout/impersonation-banner';
import { PlanCard } from '@/components/shared/plan-card';
import { SubscriptionBanner } from '@/components/layout/subscription-banner';
import { ToastContainer } from '@/components/ui';
import { useUIStore } from '@/lib/stores/ui-store';
import { useImpersonationStore } from '@/lib/stores/impersonation-store';
import { useCurrentBusiness } from '@/lib/hooks/use-business';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useSubscriptionStatus, useSubscriptionPlans } from '@/lib/hooks/use-checkout';
import { useSiteConfig } from '@/lib/hooks/use-site-config';
import { useRealtime } from '@/lib/hooks/use-realtime';
import { requestNotificationPermission } from '@/lib/utils/browser-notification';
import { formatCurrency } from '@/lib/utils/format';
import { isDemoMode } from '@/lib/demo/is-demo';
import { SUPPORT_CONFIG } from '@/lib/constants';
import { useAuthStore } from '@/lib/stores/auth-store';
import type { Plan } from '@/lib/api/types';

const DemoBanner = dynamic(() => import('@/components/shared/demo-banner'), {
  ssr: false,
});

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const { sidebarOpen, setSidebarOpen } = useUIStore();
  const { isImpersonating } = useImpersonationStore();
  const { user } = useAuthStore();
  const isAdmin = user?.role === 'admin';
  const { data: business } = useCurrentBusiness();
  const { subscription, daysUntilExpiry } = useCurrentSubscription();
  const { data: subscriptionStatus } = useSubscriptionStatus();
  const { data: plans } = useSubscriptionPlans();
  const { data: siteConfig } = useSiteConfig();
  const isBusinessSuspended = !isAdmin && business?.status === 'suspended';
  const isBusinessInactive = !isAdmin && business?.status === 'inactive';

  // Admin users skip all subscription/trial checks
  const hadSubscription = subscriptionStatus?.had_subscription ?? false;
  const trialExpired = !isAdmin &&
    !subscription &&
    !hadSubscription &&
    !!business?.trial_ends_at &&
    new Date(business.trial_ends_at) < new Date();

  const hasPendingOrder = !!subscriptionStatus?.pending_order;

  // Only block trial expired (never paid). Suspended = dashboard accessible with banner.
  const isCheckoutPage = pathname?.startsWith('/dashboard/subscription');
  const shouldBlockTrialExpired = !isAdmin && !isCheckoutPage && trialExpired && !hasPendingOrder && !isBusinessSuspended;
  const isDemo = isDemoMode();
  // Show subscription banner: trial info (all trialing), urgency (≤5 days), or expired (negative)
  const isTrialing = !subscriptionStatus?.subscription;
  const showSubscriptionBanner = daysUntilExpiry !== null && (daysUntilExpiry <= 5 || isTrialing);
  // Show "Oculto" banner only for non-subscription suspensions (e.g. manual admin action)
  const isBusinessHidden = isBusinessSuspended && !showSubscriptionBanner;

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
            href={`mailto:${SUPPORT_CONFIG.email}`}
            className="mt-6 inline-flex items-center gap-2 rounded-lg bg-violet-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-violet-700"
          >
            Contactar soporte
          </a>
        </div>
      </div>
    );
  }

  // Pending order: show "under review" screen
  if (hasPendingOrder && (trialExpired || isBusinessSuspended)) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-center max-w-md mx-auto px-4">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-yellow-100">
            <Clock className="h-8 w-8 text-yellow-600" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">
            Comprobante en revision
          </h1>
          <p className="mt-2 text-gray-600">
            Tu comprobante de pago esta siendo revisado por nuestro equipo.
            Te notificaremos cuando sea aprobado.
          </p>
        </div>
      </div>
    );
  }

  // Suspended: NOT blocked — dashboard accessible with yellow banner "Tu negocio está oculto"
  // The SubscriptionBanner shows "Tu plan venció" with link to checkout

  // Trial expired (never paid): block with "choose a plan" screen
  if (shouldBlockTrialExpired) {
    return (
      <TrialBlockScreen
        title="Tu periodo de prueba ha terminado"
        subtitle="Gracias por probar Agendity. Para seguir gestionando tu negocio, elige un plan."
        plans={plans ?? []}
        siteConfig={siteConfig}
        variant="expired"
      />
    );
  }

  // Calculate pixel offset for fixed elements based on active banners
  // Each banner is 40px tall (h-10 = 2.5rem)
  const BANNER_HEIGHT = 40;
  const bannerCount = [isDemo, isImpersonating, isBusinessHidden, showSubscriptionBanner].filter(Boolean).length;
  const bannerOffset = bannerCount * BANNER_HEIGHT;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Banners stack at the top, each one fixed and offset by the ones above */}
      {isDemo && (
        <div className="fixed left-0 right-0 z-[60]" style={{ top: 0 }}>
          <DemoBanner />
        </div>
      )}

      {isImpersonating && (
        <div className="fixed left-0 right-0 z-[59]" style={{ top: isDemo ? BANNER_HEIGHT : 0 }}>
          <ImpersonationBanner />
        </div>
      )}

      {isBusinessHidden && (
        <div
          className="fixed left-0 right-0 z-[58] flex items-center justify-center gap-2 bg-yellow-400 px-4 py-2 text-sm font-medium text-yellow-900"
          style={{ top: [isDemo, isImpersonating].filter(Boolean).length * BANNER_HEIGHT }}
        >
          <EyeOff className="h-4 w-4" />
          Tu negocio está oculto y no aparece para usuarios.
          <a
            href="/dashboard/subscription/checkout"
            className="ml-1 inline-flex items-center gap-1 rounded-md bg-yellow-900 px-3 py-1 text-xs font-semibold text-yellow-100 transition-colors hover:bg-yellow-800"
          >
            Renovar suscripción
          </a>
        </div>
      )}

      {showSubscriptionBanner && (
        <div
          className="fixed left-0 right-0 z-[57]"
          style={{ top: [isDemo, isImpersonating, isBusinessHidden].filter(Boolean).length * BANNER_HEIGHT }}
        >
          <SubscriptionBanner />
        </div>
      )}

      {/* Desktop sidebar */}
      <Sidebar topOffset={bannerOffset} />

      {/* Mobile sidebar overlay */}
      {sidebarOpen && (
        <>
          <div
            className="fixed inset-0 z-40 cursor-pointer bg-black/50 md:hidden"
            onClick={() => setSidebarOpen(false)}
          />
          <Sidebar className="!flex z-50" topOffset={bannerOffset} />
        </>
      )}

      {/* Topbar */}
      <Topbar topOffset={bannerOffset} />

      {/* Main content */}
      <main
        className="ml-0 pb-16 md:ml-64 md:pb-0"
        style={{ paddingTop: bannerOffset + 64 /* 64px = h-16 topbar */ }}
      >
        <div className="px-4 py-6 md:px-6">{children}</div>
      </main>

      {/* Mobile bottom nav */}
      <MobileNav />

      {/* Toasts */}
      <ToastContainer />
    </div>
  );
}

// --- Blocking screen for trial expired / suspended ---

interface TrialBlockScreenProps {
  title: string;
  subtitle: string;
  plans: Plan[];
  siteConfig?: {
    support_email: string | null;
    support_whatsapp: string | null;
    support_whatsapp_url: string | null;
  } | null;
  variant: 'expired' | 'suspended';
}

function TrialBlockScreen({ title, subtitle, plans, siteConfig, variant }: TrialBlockScreenProps) {
  const isSuspended = variant === 'suspended';
  const showPlans = variant === 'expired' && plans.length > 0;

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-12">
      <div className={`w-full ${showPlans ? 'max-w-4xl' : 'max-w-md'}`}>
        {/* Header */}
        <div className="text-center mb-8">
          <div className={`mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full ${isSuspended ? 'bg-red-100' : 'bg-violet-100'}`}>
            {isSuspended ? (
              <ShieldX className="h-8 w-8 text-red-600" />
            ) : (
              <Timer className="h-8 w-8 text-violet-600" />
            )}
          </div>
          <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
          <p className="mt-2 text-gray-600 max-w-lg mx-auto">{subtitle}</p>
        </div>

        {/* Plan cards with features — only for trial expired (first time choosing) */}
        {showPlans && (
          <div className="grid gap-4 sm:grid-cols-3 mb-8">
            {plans.map((plan) => (
              <PlanCard key={plan.id} plan={plan} />
            ))}
          </div>
        )}

        {/* CTA button */}
        <div className="text-center">
          <Link
            href="/dashboard/subscription/checkout"
            className={`cursor-pointer inline-flex items-center gap-2 rounded-lg transition-colors ${
              isSuspended
                ? 'border border-violet-600 bg-white px-5 py-2 text-sm font-medium text-violet-600 hover:bg-violet-50'
                : 'bg-violet-600 px-8 py-3 text-base font-semibold text-white hover:bg-violet-700'
            }`}
          >
            {isSuspended ? 'Renovar suscripcion' : 'Elegir plan y pagar'}
          </Link>
        </div>

        {/* Support link */}
        <div className="mt-6 text-center text-sm text-gray-500">
          <p>
            ¿Necesitas ayuda?{' '}
            {siteConfig?.support_whatsapp_url ? (
              <a
                href={siteConfig.support_whatsapp_url}
                target="_blank"
                rel="noopener noreferrer"
                className="font-medium text-violet-600 hover:text-violet-700"
              >
                Escríbenos por WhatsApp
              </a>
            ) : (
              <a
                href={`mailto:${siteConfig?.support_email ?? SUPPORT_CONFIG.email}`}
                className="font-medium text-violet-600 hover:text-violet-700"
              >
                Contacta soporte
              </a>
            )}
          </p>
        </div>
      </div>
    </div>
  );
}
