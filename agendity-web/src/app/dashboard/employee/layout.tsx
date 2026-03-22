'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, Calendar, ScanLine, LogOut } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { useAuthStore } from '@/lib/stores/auth-store';
import { useEmployeeDashboard } from '@/lib/hooks/use-employee-dashboard';

const NAV_ITEMS = [
  { href: '/dashboard/employee', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/dashboard/employee/appointments', label: 'Mis citas', icon: Calendar },
  { href: '/dashboard/employee/checkin', label: 'Check-in', icon: ScanLine },
];

export default function EmployeeLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const clearAuth = useAuthStore((s) => s.clearAuth);
  const { data } = useEmployeeDashboard();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top bar */}
      <header className="border-b border-gray-200 bg-white px-4 py-3">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <div className="flex items-center gap-3">
            <Link href="/dashboard/employee" className="text-lg font-bold text-violet-600">
              Agendity
            </Link>
            {data?.business && (
              <span className="rounded-full bg-gray-100 px-3 py-0.5 text-xs font-medium text-gray-600">
                {data.business.name}
              </span>
            )}
          </div>
          <div className="flex items-center gap-3">
            <span className="text-sm text-gray-700">{data?.employee?.name}</span>
            <button
              onClick={() => { clearAuth(); window.location.href = '/login'; }}
              className="cursor-pointer text-gray-400 hover:text-gray-600"
            >
              <LogOut className="h-4 w-4" />
            </button>
          </div>
        </div>
      </header>

      {/* Nav */}
      <nav className="border-b border-gray-100 bg-white">
        <div className="mx-auto flex max-w-5xl gap-1 px-4">
          {NAV_ITEMS.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center gap-2 border-b-2 px-4 py-3 text-sm font-medium transition-colors',
                  isActive
                    ? 'border-violet-600 text-violet-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700',
                )}
              >
                <item.icon className="h-4 w-4" />
                {item.label}
              </Link>
            );
          })}
        </div>
      </nav>

      {/* Content */}
      <main className="mx-auto max-w-5xl px-4 py-6">
        {children}
      </main>
    </div>
  );
}
