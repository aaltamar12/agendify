'use client';

import { useEffect, useRef } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useAuthStore } from '@/lib/stores/auth-store';
import { useEventNotifications } from '@/lib/hooks/use-event-notifications';

/**
 * NATS WebSocket hook for real-time updates.
 *
 * Connects to NATS via WebSocket and subscribes to all events for the
 * current user's business. When an event arrives, it triggers:
 * 1. TanStack Query cache invalidation (calendar, payments, etc.)
 * 2. Browser notification (native Notification API)
 * 3. Notification sound (Web Audio API chime, if enabled)
 *
 * This is a progressive enhancement — if NATS is unavailable, the
 * existing polling (refetchInterval) continues working as fallback.
 */
export function useRealtime() {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const businessId = user?.business_id;
  const { handleEvent } = useEventNotifications();
  const handleEventRef = useRef(handleEvent);

  // Keep ref up to date so the NATS callback always uses the latest handler
  useEffect(() => {
    handleEventRef.current = handleEvent;
  }, [handleEvent]);

  useEffect(() => {
    if (!businessId) return;

    let nc: any = null;
    let sub: any = null;
    let closed = false;

    const connect = async () => {
      try {
        const { connect, StringCodec } = await import('nats.ws');
        const sc = StringCodec();

        nc = await connect({
          servers: process.env.NEXT_PUBLIC_NATS_WS_URL || 'ws://localhost:8222',
        });

        if (closed) {
          nc.close();
          return;
        }

        // Subscribe to all events for this business (wildcard >)
        sub = nc.subscribe(`business.${businessId}.>`);

        (async () => {
          for await (const msg of sub) {
            try {
              const payload = JSON.parse(sc.decode(msg.data));
              handleEventRef.current(payload.event, payload.data);
            } catch {
              // Ignore malformed messages
            }
          }
        })();

        console.log('[NATS] Conectado, suscrito a business.' + businessId);
      } catch (err) {
        console.warn('[NATS] Conexión fallida, usando polling como fallback:', err);
      }
    };

    connect();

    return () => {
      closed = true;
      sub?.unsubscribe();
      nc?.close();
    };
  }, [businessId, queryClient]);
}
