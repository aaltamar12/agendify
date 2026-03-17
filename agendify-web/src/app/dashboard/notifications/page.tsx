'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Bell,
  Calendar,
  CreditCard,
  XCircle,
  Clock,
  CheckCheck,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { Card, Button, Skeleton, EmptyState } from '@/components/ui';
import {
  useNotifications,
  useMarkRead,
  useMarkAllRead,
  useUnreadCount,
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

function NotificationSkeleton() {
  return (
    <Card>
      <div className="flex items-start gap-3">
        <Skeleton className="h-10 w-10 rounded-full" />
        <div className="flex-1 space-y-2">
          <Skeleton className="h-4 w-48" />
          <Skeleton className="h-3 w-32" />
          <Skeleton className="h-3 w-20" />
        </div>
      </div>
    </Card>
  );
}

function NotificationCard({
  notification,
  onClickItem,
}: {
  notification: Notification;
  onClickItem: (n: Notification) => void;
}) {
  const config = typeConfig[notification.notification_type] ?? typeConfig.reminder;
  const Icon = config.icon;

  return (
    <Card
      className={`cursor-pointer transition-colors hover:border-gray-300 ${
        !notification.read ? 'border-l-4 border-l-violet-500' : ''
      }`}
      onClick={() => onClickItem(notification)}
    >
      <div className="flex items-start gap-3">
        <div
          className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-full ${config.bgClass}`}
        >
          <Icon className={`h-5 w-5 ${config.colorClass}`} />
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-2">
            <p
              className={`text-sm leading-tight ${
                !notification.read
                  ? 'font-semibold text-gray-900'
                  : 'text-gray-700'
              }`}
            >
              {notification.title}
            </p>
            <div className="flex shrink-0 items-center gap-2">
              <span className="whitespace-nowrap text-xs text-gray-400">
                {timeAgo(notification.created_at)}
              </span>
              {!notification.read && (
                <span className="h-2 w-2 rounded-full bg-violet-500" />
              )}
            </div>
          </div>
          {notification.body && (
            <p className="mt-1 text-sm text-gray-500">{notification.body}</p>
          )}
        </div>
      </div>
    </Card>
  );
}

export default function NotificationsPage() {
  const [page, setPage] = useState(1);
  const router = useRouter();
  const { data: response, isLoading } = useNotifications(page);
  const { data: countData } = useUnreadCount();
  const markRead = useMarkRead();
  const markAllRead = useMarkAllRead();

  const notifications = response?.data;
  const meta = response?.meta;
  const unreadCount = countData?.data?.unread_count ?? 0;

  function handleClickNotification(notification: Notification) {
    if (!notification.read) {
      markRead.mutate(notification.id);
    }
    if (notification.link) {
      router.push(notification.link);
    }
  }

  function handleMarkAllRead() {
    markAllRead.mutate();
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Notificaciones</h1>
          {meta && (
            <p className="mt-1 text-sm text-gray-500">
              {meta.total_count} notificación{meta.total_count !== 1 ? 'es' : ''}{' '}
              {unreadCount > 0 && (
                <span className="font-medium text-violet-600">
                  ({unreadCount} sin leer)
                </span>
              )}
            </p>
          )}
        </div>

        {unreadCount > 0 && (
          <Button
            variant="outline"
            size="sm"
            onClick={handleMarkAllRead}
            disabled={markAllRead.isPending}
          >
            <CheckCheck className="mr-1.5 h-4 w-4" />
            Marcar todas como leídas
          </Button>
        )}
      </div>

      {/* Loading state */}
      {isLoading && (
        <div className="space-y-4">
          {Array.from({ length: 5 }).map((_, i) => (
            <NotificationSkeleton key={i} />
          ))}
        </div>
      )}

      {/* Empty state */}
      {!isLoading && (!notifications || notifications.length === 0) && (
        <EmptyState
          icon={Bell}
          title="No hay notificaciones"
          description="Las notificaciones de nuevas reservas, pagos y cancelaciones aparecerán aquí."
        />
      )}

      {/* Notification list */}
      {!isLoading && notifications && notifications.length > 0 && (
        <div className="space-y-3">
          {notifications.map((notification) => (
            <NotificationCard
              key={notification.id}
              notification={notification}
              onClickItem={handleClickNotification}
            />
          ))}
        </div>
      )}

      {/* Pagination */}
      {meta && meta.total_pages > 1 && (
        <div className="mt-6 flex items-center justify-between">
          <p className="text-sm text-gray-500">
            Página {meta.current_page} de {meta.total_pages}
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
            >
              <ChevronLeft className="h-4 w-4" />
              Anterior
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= meta.total_pages}
              onClick={() => setPage((p) => p + 1)}
            >
              Siguiente
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
