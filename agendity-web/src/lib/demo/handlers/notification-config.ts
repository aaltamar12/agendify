// ============================================================
// Agendity — Demo handlers: notification config
// ============================================================

import { route } from '../router';

// GET /api/v1/notification_config
route('get', '/api/v1/notification_config', () => {
  return {
    data: {
      whatsapp_enabled: true,
      whatsapp_booking_confirmation: true,
      whatsapp_booking_reminder: true,
      whatsapp_reminder_hours_before: 2,
      whatsapp_payment_confirmation: true,
      whatsapp_cancellation_notice: true,
      whatsapp_review_request: true,
      whatsapp_review_delay_hours: 1,
      whatsapp_cashback_notification: true,
      email_enabled: false,
      email_booking_confirmation: false,
      email_payment_confirmation: false,
      push_enabled: true,
      push_new_booking: true,
      push_payment_received: true,
      push_cancellation: true,
      push_review: true,
    },
  };
});

// PUT /api/v1/notification_config
route('put', '/api/v1/notification_config', ({ body }) => {
  // In demo mode we just echo back the config
  const data = (body as any)?.notification_config ?? body;
  return { data };
});
