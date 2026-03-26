'use client';

import { useCallback } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useUIStore } from '@/lib/stores/ui-store';
import { playNotificationSound } from '@/lib/utils/notification-sound';
import { showBrowserNotification } from '@/lib/utils/browser-notification';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

interface NotificationEventConfig {
  event_key: string;
  title: string;
  body_template: string | null;
  browser_notification: boolean;
  sound_enabled: boolean;
  in_app_notification: boolean;
  active: boolean;
}

// Hardcoded fallback if backend config is unavailable
const FALLBACK_CONFIG: Record<string, { title: string; body_template: string; browser_notification: boolean; sound_enabled: boolean }> = {
  new_booking: { title: 'Nueva reserva', body_template: '{{customer_name}} reservó {{service_name}}', browser_notification: true, sound_enabled: true },
  payment_submitted: { title: 'Comprobante recibido', body_template: '{{customer_name}} envió un comprobante de pago', browser_notification: true, sound_enabled: true },
  booking_cancelled: { title: 'Cita cancelada', body_template: '{{customer_name}} canceló su cita', browser_notification: true, sound_enabled: true },
  booking_confirmed: { title: 'Pago confirmado', body_template: 'Pago confirmado para {{customer_name}}', browser_notification: true, sound_enabled: true },
  appointment_completed: { title: 'Cita completada', body_template: '{{customer_name}} completó su cita', browser_notification: false, sound_enabled: false },
  ai_suggestion: { title: 'Sugerencia inteligente', body_template: 'Detectamos oportunidades para optimizar tus precios', browser_notification: false, sound_enabled: false },
  birthday: { title: 'Cumpleaños', body_template: 'Hoy es cumpleaños de {{customer_name}}', browser_notification: true, sound_enabled: true },
};

// Replace {{variable}} placeholders with data values
function renderTemplate(template: string, data: Record<string, unknown>): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_, key) => String(data[key] || ''));
}

export function useEventNotifications() {
  const queryClient = useQueryClient();
  const userSoundEnabled = useUIStore((s) => s.notificationSoundEnabled);

  // Fetch notification config from backend (cached, refreshes every 5 min)
  const { data: serverConfigs } = useQuery({
    queryKey: ['notification-config'],
    queryFn: () => get<ApiResponse<NotificationEventConfig[]>>(ENDPOINTS.NOTIFICATION_CONFIG.list),
    select: (res) => res.data,
    staleTime: 5 * 60 * 1000,
    retry: 1,
  });

  const handleEvent = useCallback(
    (event: string, data: Record<string, unknown>) => {
      // 1. Invalidate relevant queries (always, regardless of config)
      if (['new_booking', 'booking_cancelled', 'booking_confirmed'].includes(event)) {
        queryClient.invalidateQueries({ queryKey: ['appointments'] });
      }
      if (event === 'payment_submitted') {
        queryClient.invalidateQueries({ queryKey: ['payments'] });
      }
      if (event === 'appointment_completed') {
        queryClient.invalidateQueries({ queryKey: ['appointments'] });
        queryClient.invalidateQueries({ queryKey: ['cash-register-today'] });
      }
      if (event === 'ai_suggestion') {
        queryClient.invalidateQueries({ queryKey: ['dynamic-pricing'] });
        queryClient.invalidateQueries({ queryKey: ['dynamic-pricing-suggestions-count'] });
      }
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      queryClient.invalidateQueries({ queryKey: ['notificationsUnreadCount'] });

      // 2. Get config for this event (server or fallback)
      const serverConfig = serverConfigs?.find((c) => c.event_key === event && c.active);
      const fallback = FALLBACK_CONFIG[event];

      const title = serverConfig?.title || fallback?.title;
      const bodyTemplate = serverConfig?.body_template || fallback?.body_template || '';
      const showBrowser = serverConfig?.browser_notification ?? fallback?.browser_notification ?? false;
      const playSound = serverConfig?.sound_enabled ?? fallback?.sound_enabled ?? false;

      // 3. Show browser notification if enabled
      if (showBrowser && title) {
        const body = renderTemplate(bodyTemplate, data);
        showBrowserNotification(title, {
          body,
          tag: `agendity-${event}-${Date.now()}`,
        });
      }

      // 4. Play sound if both server config and user preference allow it
      if (playSound && userSoundEnabled) {
        playNotificationSound();
      }
    },
    [queryClient, userSoundEnabled, serverConfigs],
  );

  return { handleEvent };
}
