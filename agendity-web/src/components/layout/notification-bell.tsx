'use client';

import { useState, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Bell,
  Calendar,
  CreditCard,
  XCircle,
  Clock,
  CheckCheck,
} from 'lucide-react';
import {
  useNotifications,
  useUnreadCount,
  useMarkRead,
  useMarkAllRead,
} from '@/lib/hooks/use-notifications';
import type { Notification, NotificationType } from '@/lib/api/types';

// --- Icon config by notification type ---

const typeConfig: Record<
  NotificationType,
  { icon: typeof Calendar; colorClass: string; bgClass: string }
> = {
  new_booking: {
    icon: Calendar,
    colorClass: 'text-violet-600',
    bgClass: 'bg-violet-100',
  },
  payment_submitted: {
    icon: CreditCard,
    colorClass: 'text-blue-600',
    bgClass: 'bg-blue-100',
  },
  payment_approved: {
    icon: CreditCard,
    colorClass: 'text-green-600',
    bgClass: 'bg-green-100',
  },
  booking_cancelled: {
    icon: XCircle,
    colorClass: 'text-red-600',
    bgClass: 'bg-red-100',
  },
  reminder: {
    icon: Clock,
    colorClass: 'text-amber-600',
    bgClass: 'bg-amber-100',
  },
};

function timeAgo(dateStr: string): string {
  const now = new Date();
  const date = new Date(dateStr);
  const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (seconds < 60) return 'Ahora';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `Hace ${minutes} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `Hace ${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `Hace ${days}d`;
  return date.toLocaleDateString('es-CO', { day: 'numeric', month: 'short' });
}

function NotificationItem({
  notification,
  onClickItem,
}: {
  notification: Notification;
  onClickItem: (n: Notification) => void;
}) {
  const config = typeConfig[notification.notification_type] ?? typeConfig.reminder;
  const Icon = config.icon;

  return (
    <button
      onClick={() => onClickItem(notification)}
      className={`flex w-full items-start gap-3 px-4 py-3 text-left transition-colors hover:bg-gray-50 ${
        !notification.read ? 'bg-violet-50/50' : ''
      }`}
    >
      <div
        className={`mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full ${config.bgClass}`}
      >
        <Icon className={`h-4 w-4 ${config.colorClass}`} />
      </div>
      <div className="min-w-0 flex-1">
        <p
          className={`text-sm leading-tight ${
            !notification.read ? 'font-semibold text-gray-900' : 'text-gray-700'
          }`}
        >
          {notification.title}
        </p>
        {notification.body && (
          <p className="mt-0.5 truncate text-xs text-gray-500">
            {notification.body}
          </p>
        )}
        <p className="mt-1 text-xs text-gray-400">
          {timeAgo(notification.created_at)}
        </p>
      </div>
      {!notification.read && (
        <span className="mt-2 h-2 w-2 shrink-0 rounded-full bg-violet-500" />
      )}
    </button>
  );
}

export function NotificationBell() {
  const [open, setOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const router = useRouter();

  const { data: countData } = useUnreadCount();
  const { data: response } = useNotifications(1);
  const markRead = useMarkRead();
  const markAllRead = useMarkAllRead();

  const unreadCount = countData?.data?.unread_count ?? 0;
  const notifications = response?.data?.slice(0, 5) ?? [];

  // Close dropdown on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setOpen(false);
      }
    }

    if (open) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [open]);

  function handleClickNotification(notification: Notification) {
    if (!notification.read) {
      markRead.mutate(notification.id);
    }
    setOpen(false);
    if (notification.link) {
      router.push(notification.link);
    }
  }

  function handleMarkAllRead() {
    markAllRead.mutate();
  }

  function handleViewAll() {
    setOpen(false);
    router.push('/dashboard/notifications');
  }

  return (
    <div ref={dropdownRef} className="relative">
      {/* Bell button */}
      <button
        onClick={() => setOpen((prev) => !prev)}
        className="relative rounded-lg p-2 text-gray-600 transition-colors hover:bg-gray-100"
        aria-label="Notificaciones"
      >
        <Bell className="h-5 w-5" />
        {unreadCount > 0 && (
          <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-[1rem] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {/* Dropdown panel */}
      {open && (
        <div className="absolute right-0 top-full z-50 mt-2 w-80 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-lg sm:w-96">
          {/* Header */}
          <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3">
            <h3 className="text-sm font-semibold text-gray-900">
              Notificaciones
            </h3>
            {unreadCount > 0 && (
              <button
                onClick={handleMarkAllRead}
                className="flex items-center gap-1 text-xs font-medium text-violet-600 transition-colors hover:text-violet-700"
              >
                <CheckCheck className="h-3.5 w-3.5" />
                Marcar todas como leídas
              </button>
            )}
          </div>

          {/* Notification list */}
          {notifications.length > 0 ? (
            <div className="max-h-80 divide-y divide-gray-50 overflow-y-auto">
              {notifications.map((notification) => (
                <NotificationItem
                  key={notification.id}
                  notification={notification}
                  onClickItem={handleClickNotification}
                />
              ))}
            </div>
          ) : (
            <div className="px-4 py-8 text-center">
              <Bell className="mx-auto h-8 w-8 text-gray-300" />
              <p className="mt-2 text-sm text-gray-500">
                No hay notificaciones
              </p>
            </div>
          )}

          {/* Footer */}
          <div className="border-t border-gray-100">
            <button
              onClick={handleViewAll}
              className="block w-full px-4 py-2.5 text-center text-sm font-medium text-violet-600 transition-colors hover:bg-gray-50"
            >
              Ver todas
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
