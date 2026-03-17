'use client';

import { Menu } from 'lucide-react';
import { useAuthStore } from '@/lib/stores/auth-store';
import { useUIStore } from '@/lib/stores/ui-store';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useCurrentBusiness } from '@/lib/hooks/use-business';
import { PLAN_DISPLAY } from '@/lib/constants';
import { Avatar } from '@/components/ui';
import { NotificationBell } from '@/components/layout/notification-bell';
import { HelpButton } from '@/components/layout/help-button';
import { AdminImpersonateDropdown } from '@/components/layout/admin-impersonate-dropdown';

interface TopbarProps {
  topOffset?: number;
}

export function Topbar({ topOffset = 0 }: TopbarProps) {
  const { user } = useAuthStore();
  const { toggleSidebar } = useUIStore();
  const { planSlug } = useCurrentSubscription();
  const { data: business } = useCurrentBusiness();

  const display = PLAN_DISPLAY[planSlug];
  const isHidden = business?.status === 'suspended';

  return (
    <header
      className="fixed left-0 right-0 z-20 flex h-16 items-center justify-between border-b border-gray-200 bg-white px-4 md:left-64"
      style={{ top: topOffset }}
    >
      {/* Left: hamburger (mobile) */}
      <div className="flex items-center gap-3">
        <button
          onClick={toggleSidebar}
          className="rounded-lg p-2 text-gray-600 hover:bg-gray-100 transition-colors md:hidden"
          aria-label="Abrir menú"
        >
          <Menu className="h-5 w-5" />
        </button>
      </div>

      {/* Right */}
      <div className="flex items-center gap-2">
        {/* Admin impersonation (left side) */}
        <AdminImpersonateDropdown />

        {/* Notification + Help */}
        <NotificationBell />
        <HelpButton />

        {/* Separator */}
        <div className="mx-1 hidden h-8 w-px bg-gray-200 sm:block" />

        {/* Plan badge + Name + Avatar (right side) */}
        <div className="hidden flex-col items-end sm:flex">
          <div className="flex items-center gap-1.5">
            <span className="text-sm font-medium text-gray-700">
              {user?.name ?? 'Mi Negocio'}
            </span>
            {isHidden && (
              <span className="inline-flex items-center rounded-full bg-yellow-100 px-2 py-0.5 text-[10px] font-semibold text-yellow-800 ring-1 ring-inset ring-yellow-300">
                Oculto
              </span>
            )}
          </div>
          <span
            className={`mt-0.5 inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${display.bgClass} ${display.textClass}`}
          >
            Plan {display.badge}
          </span>
        </div>
        <Avatar name={user?.name ?? 'U'} src={user?.avatar_url} size="sm" />
      </div>
    </header>
  );
}
