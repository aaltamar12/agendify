// ============================================================
// Agendify — Demo seed: notifications
// ============================================================

import type { Notification } from '@/lib/api/types';

export function seedNotifications(): Notification[] {
  const now = new Date();

  function hoursAgo(h: number): string {
    const d = new Date(now.getTime() - h * 60 * 60 * 1000);
    return d.toISOString();
  }

  return [
    {
      id: 1,
      title: 'Nueva reserva',
      body: 'Santiago Ospina reservó Corte Clásico para mañana a las 9:00 AM',
      notification_type: 'new_booking',
      link: '/dashboard/agenda',
      read: false,
      created_at: hoursAgo(1),
    },
    {
      id: 2,
      title: 'Comprobante recibido',
      body: 'Alejandro Peña envió comprobante de pago para Fade Degradado',
      notification_type: 'payment_submitted',
      link: '/dashboard/payments',
      read: false,
      created_at: hoursAgo(2),
    },
    {
      id: 3,
      title: 'Nueva reserva',
      body: 'Valentina Restrepo reservó Corte + Barba para el miércoles a las 2:00 PM',
      notification_type: 'new_booking',
      link: '/dashboard/agenda',
      read: false,
      created_at: hoursAgo(4),
    },
    {
      id: 4,
      title: 'Comprobante recibido',
      body: 'Paula Andrea Ríos envió comprobante de pago para Afeitado Clásico',
      notification_type: 'payment_submitted',
      link: '/dashboard/payments',
      read: false,
      created_at: hoursAgo(6),
    },
    {
      id: 5,
      title: 'Cita cancelada',
      body: 'Isabella Moreno canceló su cita de Fade Degradado. Motivo: No puedo asistir',
      notification_type: 'booking_cancelled',
      link: '/dashboard/agenda',
      read: true,
      created_at: hoursAgo(12),
    },
    {
      id: 6,
      title: 'Pago aprobado',
      body: 'Se confirmó el pago de Daniel Acosta para Corte Clásico',
      notification_type: 'payment_approved',
      link: '/dashboard/agenda',
      read: true,
      created_at: hoursAgo(24),
    },
    {
      id: 7,
      title: 'Nueva reserva',
      body: 'Mateo Jiménez reservó Corte + Barba para el viernes a las 11:00 AM',
      notification_type: 'new_booking',
      link: '/dashboard/agenda',
      read: true,
      created_at: hoursAgo(36),
    },
    {
      id: 8,
      title: 'Recordatorio',
      body: 'Mañana tienes 5 citas programadas. Revisa tu agenda.',
      notification_type: 'reminder',
      link: '/dashboard/agenda',
      read: true,
      created_at: hoursAgo(48),
    },
  ];
}
