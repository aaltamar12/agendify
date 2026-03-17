'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Calendar, Scissors, Users, CreditCard, MoreHorizontal } from 'lucide-react';
import { cn } from '@/lib/utils/cn';

const mobileItems = [
  { href: '/dashboard/agenda', label: 'Agenda', icon: Calendar },
  { href: '/dashboard/services', label: 'Servicios', icon: Scissors },
  { href: '/dashboard/employees', label: 'Empleados', icon: Users },
  { href: '/dashboard/payments', label: 'Pagos', icon: CreditCard },
  { href: '/dashboard/settings', label: 'Más', icon: MoreHorizontal },
] as const;

export function MobileNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-20 flex h-16 items-center justify-around border-t border-gray-200 bg-white md:hidden">
      {mobileItems.map(({ href, label, icon: Icon }) => {
        const isActive = pathname.startsWith(href);
        return (
          <Link
            key={href}
            href={href}
            className={cn(
              'flex flex-col items-center gap-0.5 px-2 py-1 text-[10px] transition-colors',
              isActive ? 'text-violet-600' : 'text-gray-500'
            )}
          >
            <Icon className="h-5 w-5" />
            <span>{label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
