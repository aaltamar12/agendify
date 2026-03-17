// ============================================================
// Agendity — Demo handlers: payments
// ============================================================

import { route } from '../router';
import { getStore, updateStore } from '../store';

// POST /api/v1/payments/:id/approve
route('post', '/api/v1/payments/:id/approve', ({ params }) => {
  const id = Number(params.id);
  const now = new Date().toISOString();

  updateStore((s) => {
    const payment = s.payments.find((p) => p.id === id);
    if (payment) {
      payment.status = 'approved';
      payment.approved_at = now;
    }

    // Also update appointment status
    const apt = s.appointments.find((a) => a.payment?.id === id);
    if (apt) {
      apt.status = 'confirmed';
      apt.updated_at = now;
      if (apt.payment) {
        apt.payment.status = 'approved';
        apt.payment.approved_at = now;
      }
    }
  });

  const store = getStore();
  const payment = store.payments.find((p) => p.id === id);
  return { data: payment };
});

// POST /api/v1/payments/:id/reject
route('post', '/api/v1/payments/:id/reject', ({ params, body }) => {
  const id = Number(params.id);
  const reason = (body as any)?.rejection_reason ?? 'Rechazado en demo';
  const now = new Date().toISOString();

  updateStore((s) => {
    const payment = s.payments.find((p) => p.id === id);
    if (payment) {
      payment.status = 'rejected';
      payment.rejected_at = now;
      payment.rejection_reason = reason;
    }

    // Revert appointment to pending_payment
    const apt = s.appointments.find((a) => a.payment?.id === id);
    if (apt) {
      apt.status = 'pending_payment';
      apt.updated_at = now;
      if (apt.payment) {
        apt.payment.status = 'rejected';
        apt.payment.rejected_at = now;
        apt.payment.rejection_reason = reason;
      }
    }
  });

  const store = getStore();
  const payment = store.payments.find((p) => p.id === id);
  return { data: payment };
});

// POST /api/v1/appointments/:appointmentId/payments/submit
route('post', '/api/v1/appointments/:appointmentId/payments/submit', ({ params }) => {
  const appointmentId = Number(params.appointmentId);
  const now = new Date().toISOString();

  updateStore((s) => {
    const apt = s.appointments.find((a) => a.id === appointmentId);
    if (apt) {
      apt.status = 'payment_sent';
      apt.updated_at = now;

      // Create or update payment
      let payment = s.payments.find((p) => p.appointment_id === appointmentId);
      if (!payment) {
        payment = {
          id: s.nextIds.payment++,
          appointment_id: appointmentId,
          amount: apt.price,
          status: 'submitted',
          payment_method: 'nequi',
          reference: 'DEMO-' + appointmentId,
          proof_url: '/demo-proof.jpg',
          submitted_at: now,
          approved_at: null,
          rejected_at: null,
          rejection_reason: null,
          created_at: now,
          updated_at: now,
        };
        s.payments.push(payment);
      } else {
        payment.status = 'submitted';
        payment.submitted_at = now;
      }

      apt.payment = payment;
    }
  });

  return { data: { status: 'submitted' } };
});
