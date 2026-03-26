'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Calendar,
  Scissors,
  Users,
  UserCheck,
  CreditCard,
  ScanLine,
  BarChart3,
  Star,
  QrCode,
  Settings,
  LogOut,
  Lock,
  Sparkles,
  Wallet,
  Coins,
  TrendingUp,
  Target,
} from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { cn } from '@/lib/utils/cn';
import { useAuthStore } from '@/lib/stores/auth-store';
import { useCurrentBusiness } from '@/lib/hooks/use-business';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import { PLAN_FEATURE_LOCKS, AI_FEATURES_PLANS } from '@/lib/constants';
import type { PlanSlug } from '@/lib/constants';
import type { LucideIcon } from 'lucide-react';

interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
}

const navItems: NavItem[] = [
  { href: '/dashboard/agenda', label: 'Agenda', icon: Calendar },
  { href: '/dashboard/services', label: 'Servicios', icon: Scissors },
  { href: '/dashboard/employees', label: 'Empleados', icon: Users },
  { href: '/dashboard/customers', label: 'Clientes', icon: UserCheck },
  { href: '/dashboard/payments', label: 'Pagos', icon: CreditCard },
  { href: '/dashboard/checkin', label: 'Check-in', icon: ScanLine },
  { href: '/dashboard/credits', label: 'Creditos', icon: Coins },
  { href: '/dashboard/dynamic-pricing', label: 'Tarifas dinamicas', icon: TrendingUp },
  { href: '/dashboard/cash-register', label: 'Cierre de caja', icon: Wallet },
  { href: '/dashboard/goals', label: 'Metas', icon: Target },
  { href: '/dashboard/reconciliation', label: 'Reconciliacion', icon: Sparkles },
  { href: '/dashboard/reports', label: 'Reportes', icon: BarChart3 },
  { href: '/dashboard/reviews', label: 'Reseñas', icon: Star },
  { href: '/dashboard/qr', label: 'Código QR', icon: QrCode },
  { href: '/dashboard/settings', label: 'Configuración', icon: Settings },
];

interface SidebarProps {
  className?: string;
  topOffset?: number;
}

export function Sidebar({ className, topOffset = 0 }: SidebarProps) {
  const pathname = usePathname();
  const { user, clearAuth } = useAuthStore();
  const { planSlug } = useCurrentSubscription();
  const { data: business } = useCurrentBusiness();
  const isIndependent = business?.independent ?? false;
  const isAIPlan = AI_FEATURES_PLANS.includes(planSlug);

  // Count pending AI suggestions for badge
  const { data: pricingSuggestions } = useQuery({
    queryKey: ['dynamic-pricing-suggestions-count'],
    queryFn: () => get<{ data: { id: number; status: string }[] }>(ENDPOINTS.DYNAMIC_PRICING.list, { params: { status: 'suggested' } }),
    select: (res) => res.data?.length ?? 0,
    enabled: isAIPlan,
    refetchInterval: 60000, // refresh every minute
  });

  const suggestionsCount = pricingSuggestions ?? 0;

  const handleLogout = () => {
    clearAuth();
    window.location.href = '/login';
  };

  return (
    <aside
      className={cn("fixed left-0 z-30 hidden w-64 flex-col border-r border-gray-200 bg-white md:flex", className)}
      style={{ top: topOffset, height: `calc(100vh - ${topOffset}px)` }}
    >
      {/* Logo */}
      <div className="flex h-16 items-center px-6">
        <Link href="/dashboard/agenda" className="flex items-center gap-2">
          {business?.logo_url && (
            <img
              src={business.logo_url}
              alt={business.name}
              className="h-8 w-8 rounded-full object-cover"
            />
          )}
          <span className="text-xl font-bold text-violet-600">Agendity</span>
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 px-3 py-4">
        {navItems
          .filter((item) => !isIndependent || item.href !== '/dashboard/employees')
          .map((item) => (
          <SidebarItem
            key={item.href}
            item={item}
            isActive={pathname.startsWith(item.href)}
            planSlug={planSlug}
            badge={item.href === '/dashboard/dynamic-pricing' && suggestionsCount > 0 ? suggestionsCount : undefined}
          />
        ))}
      </nav>

      {/* User + Logout */}
      <div className="border-t border-gray-200 px-3 py-4">
        <div className="flex items-center justify-between px-3">
          <span className="truncate text-sm font-medium text-gray-700">
            {user?.name ?? 'Usuario'}
          </span>
          <button
            onClick={handleLogout}
            className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors"
            aria-label="Cerrar sesión"
          >
            <LogOut className="h-4 w-4" />
          </button>
        </div>
      </div>
    </aside>
  );
}

// --- Sidebar item with lock/AI badges ---

interface SidebarItemProps {
  item: NavItem;
  isActive: boolean;
  planSlug: PlanSlug;
  badge?: number;
}

function SidebarItem({ item, isActive, planSlug, badge }: SidebarItemProps) {
  const [showTooltip, setShowTooltip] = useState(false);
  const { href, label, icon: Icon } = item;

  const lock = PLAN_FEATURE_LOCKS[href];
  const isLocked = lock ? !lock.requiredPlans.includes(planSlug) : false;

  // Show AI sparkle badge for AI-only features (if user is on inteligente plan)
  const isAIFeature = AI_FEATURES_PLANS.includes(planSlug) && href.includes('ai');

  return (
    <div className="relative">
      <Link
        href={isLocked ? '#' : href}
        onClick={(e) => {
          if (isLocked) {
            e.preventDefault();
            setShowTooltip(true);
            setTimeout(() => setShowTooltip(false), 2500);
          }
        }}
        onMouseEnter={() => { if (isLocked) setShowTooltip(true); }}
        onMouseLeave={() => { if (isLocked) setShowTooltip(false); }}
        className={cn(
          'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm transition-colors',
          isLocked
            ? 'text-gray-400 cursor-not-allowed'
            : isActive
              ? 'bg-violet-50 font-medium text-violet-700'
              : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
        )}
      >
        <Icon className="h-5 w-5 shrink-0" />
        <span className="flex-1">{label}</span>
        {isLocked && <Lock className="h-3.5 w-3.5 text-gray-400" />}
        {isAIFeature && <Sparkles className="h-3.5 w-3.5 text-amber-500" />}
        {badge && badge > 0 && (
          <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-amber-500 px-1.5 text-[10px] font-bold text-white">
            {badge}
          </span>
        )}
      </Link>

      {/* Lock tooltip */}
      {showTooltip && isLocked && lock && (
        <div className="absolute left-full top-1/2 z-50 ml-2 -translate-y-1/2 whitespace-nowrap rounded-lg bg-gray-900 px-3 py-1.5 text-xs text-white shadow-lg">
          {lock.tooltip}
          <div className="absolute right-full top-1/2 -translate-y-1/2 border-4 border-transparent border-r-gray-900" />
        </div>
      )}
    </div>
  );
}
