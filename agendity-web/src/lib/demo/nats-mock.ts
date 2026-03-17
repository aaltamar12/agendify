// ============================================================
// Agendity — Demo NATS mock (periodic fake events)
// ============================================================

import { getStore, updateStore, nextId } from './store';

let intervalId: ReturnType<typeof setInterval> | null = null;

const EVENT_TYPES = ['new_booking', 'payment_submitted'] as const;

const CUSTOMER_NAMES = [
  'Luis Martínez',
  'Andrea Gómez',
  'Ricardo Henao',
  'Sara Montoya',
  'Jorge Villalba',
];

/**
 * Start simulating NATS events every 45–60 seconds.
 * Each event creates a notification in the store.
 */
export function startNatsMock(): void {
  if (intervalId) return;

  function scheduleNext() {
    const delay = 45000 + Math.random() * 15000; // 45-60s
    intervalId = setTimeout(() => {
      emitRandomEvent();
      scheduleNext();
    }, delay);
  }

  scheduleNext();
  console.log('[DEMO] NATS mock started — events every 45-60s');
}

export function stopNatsMock(): void {
  if (intervalId) {
    clearTimeout(intervalId);
    intervalId = null;
  }
}

function emitRandomEvent(): void {
  const store = getStore();
  const eventType = EVENT_TYPES[Math.floor(Math.random() * EVENT_TYPES.length)];
  const customerName = CUSTOMER_NAMES[Math.floor(Math.random() * CUSTOMER_NAMES.length)];
  const service = store.services[Math.floor(Math.random() * store.services.length)];

  let title: string;
  let body: string;

  if (eventType === 'new_booking') {
    title = 'Nueva reserva';
    body = `${customerName} reservó ${service?.name ?? 'un servicio'} para mañana`;
  } else {
    title = 'Comprobante recibido';
    body = `${customerName} envió comprobante de pago para ${service?.name ?? 'un servicio'}`;
  }

  updateStore((s) => {
    s.notifications.unshift({
      id: nextId('notification'),
      title,
      body,
      notification_type: eventType,
      link: eventType === 'new_booking' ? '/dashboard/agenda' : '/dashboard/payments',
      read: false,
      created_at: new Date().toISOString(),
    });
  });

  // Dispatch custom event so useRealtime-like consumers can react
  if (typeof window !== 'undefined') {
    window.dispatchEvent(
      new CustomEvent('demo:nats-event', {
        detail: { event: eventType, data: { title, body, customer_name: customerName } },
      }),
    );
  }

  console.log(`[DEMO] NATS event: ${eventType} — ${customerName}`);
}
