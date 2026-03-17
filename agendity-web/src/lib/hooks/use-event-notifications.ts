'use client';

import { useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useUIStore } from '@/lib/stores/ui-store';
import { playNotificationSound } from '@/lib/utils/notification-sound';
import { showBrowserNotification } from '@/lib/utils/browser-notification';

// Maps real-time events to user-friendly notifications
const EVENT_CONFIG: Record<string, { title: string; getBody: (data: any) => string }> = {
  new_booking: {
    title: 'Nueva reserva',
    getBody: (data) =>
      `${data.customer_name || 'Un cliente'} reservó ${data.service_name || 'un servicio'}`,
  },
  payment_submitted: {
    title: 'Comprobante recibido',
    getBody: (data) =>
      `${data.customer_name || 'Un cliente'} envió un comprobante de pago`,
  },
  booking_cancelled: {
    title: 'Cita cancelada',
    getBody: (data) =>
      `${data.customer_name || 'Un cliente'} canceló su cita`,
  },
  booking_confirmed: {
    title: 'Pago confirmado',
    getBody: (data) =>
      `Pago confirmado para ${data.customer_name || 'un cliente'}`,
  },
};

export function useEventNotifications() {
  const queryClient = useQueryClient();
  const soundEnabled = useUIStore((s) => s.notificationSoundEnabled);

  const handleEvent = useCallback(
    (event: string, data: any) => {
      // 1. Invalidate relevant queries (updates calendar, payments, etc.)
      if (['new_booking', 'booking_cancelled', 'booking_confirmed'].includes(event)) {
        queryClient.invalidateQueries({ queryKey: ['appointments'] });
      }
      if (event === 'payment_submitted') {
        queryClient.invalidateQueries({ queryKey: ['payments'] });
      }
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      queryClient.invalidateQueries({ queryKey: ['notificationsUnreadCount'] });

      // 2. Show browser notification
      const config = EVENT_CONFIG[event];
      if (config) {
        showBrowserNotification(config.title, {
          body: config.getBody(data),
          tag: `agendity-${event}-${Date.now()}`,
        });
      }

      // 3. Play sound if enabled
      if (soundEnabled) {
        playNotificationSound();
      }
    },
    [queryClient, soundEnabled],
  );

  return { handleEvent };
}
