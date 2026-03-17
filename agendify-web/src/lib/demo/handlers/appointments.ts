// ============================================================
// Agendify — Demo handlers: appointments CRUD + state transitions
// ============================================================

import { route } from '../router';
import { getStore, updateStore, nextId } from '../store';
import type { Appointment, Payment } from '@/lib/api/types';

function generateTicketCode(): string {
  return 'TK' + Math.random().toString(36).substring(2, 8).toUpperCase();
}

// GET /api/v1/appointments
route('get', '/api/v1/appointments', ({ query }) => {
  const store = getStore();
  let filtered = [...store.appointments];

  if (query.date) {
    filtered = filtered.filter((a) => a.date === query.date);
  }
  if (query.status) {
    filtered = filtered.filter((a) => a.status === query.status);
  }
  if (query.employee_id) {
    filtered = filtered.filter((a) => a.employee_id === Number(query.employee_id));
  }
  if (query.payment_status) {
    filtered = filtered.filter((a) => a.payment?.status === query.payment_status);
  }

  // Enrich with relations
  const enriched = filtered.map((a) => enrichAppointment(a, store));

  return { data: enriched };
});

// POST /api/v1/appointments
route('post', '/api/v1/appointments', ({ body }) => {
  const data = (body as any)?.appointment ?? body;
  const store = getStore();
  const now = new Date().toISOString();
  const service = store.services.find((s) => s.id === Number(data.service_id));
  const employee = store.employees.find((e) => e.id === Number(data.employee_id));

  // Find or create customer
  let customer = store.customers.find(
    (c) => c.name === data.customer_name || c.phone === data.customer_phone,
  );
  if (!customer) {
    customer = {
      id: nextId('customer'),
      business_id: 1,
      name: data.customer_name ?? 'Cliente',
      phone: data.customer_phone ?? '',
      email: data.customer_email ?? null,
      notes: null,
      total_visits: 0,
      last_visit_at: null,
      created_at: now,
      updated_at: now,
    };
    updateStore((s) => s.customers.push(customer!));
  }

  const duration = service?.duration_minutes ?? 30;
  const [h, m] = (data.start_time ?? '09:00').split(':').map(Number);
  const endMinutes = h * 60 + m + duration;
  const endTime = `${String(Math.floor(endMinutes / 60)).padStart(2, '0')}:${String(endMinutes % 60).padStart(2, '0')}`;

  const appointmentId = nextId('appointment');
  const appointment: Appointment = {
    id: appointmentId,
    business_id: 1,
    employee_id: Number(data.employee_id),
    service_id: Number(data.service_id),
    customer_id: customer.id,
    date: data.date ?? data.appointment_date ?? new Date().toISOString().split('T')[0],
    start_time: data.start_time ?? '09:00',
    end_time: endTime,
    status: 'pending_payment',
    price: service?.price ?? 0,
    notes: data.notes ?? null,
    cancellation_reason: null,
    cancelled_by: null,
    ticket_code: generateTicketCode(),
    created_at: now,
    updated_at: now,
    employee,
    service,
    customer,
  };

  updateStore((s) => {
    s.appointments.push(appointment);
  });

  return { data: appointment };
});

// PUT /api/v1/appointments/:id
route('put', '/api/v1/appointments/:id', ({ params, body }) => {
  const id = Number(params.id);
  const data = (body as any)?.appointment ?? body;
  const store = getStore();

  updateStore((s) => {
    const apt = s.appointments.find((a) => a.id === id);
    if (apt) {
      Object.assign(apt, data, { updated_at: new Date().toISOString() });
    }
  });

  const updated = getStore().appointments.find((a) => a.id === id);
  return { data: updated ? enrichAppointment(updated, getStore()) : null };
});

// POST /api/v1/appointments/:id/cancel
route('post', '/api/v1/appointments/:id/cancel', ({ params, body }) => {
  const id = Number(params.id);
  const data = body as any;

  updateStore((s) => {
    const apt = s.appointments.find((a) => a.id === id);
    if (apt) {
      apt.status = 'cancelled';
      apt.cancellation_reason = data?.cancellation_reason ?? 'Cancelado en demo';
      apt.cancelled_by = data?.cancelled_by ?? 'business';
      apt.updated_at = new Date().toISOString();
    }
  });

  const updated = getStore().appointments.find((a) => a.id === id);
  return { data: updated ? enrichAppointment(updated, getStore()) : null };
});

// POST /api/v1/appointments/:id/confirm
route('post', '/api/v1/appointments/:id/confirm', ({ params }) => {
  const id = Number(params.id);

  updateStore((s) => {
    const apt = s.appointments.find((a) => a.id === id);
    if (apt) {
      apt.status = 'confirmed';
      apt.updated_at = new Date().toISOString();
      // Update payment if exists
      const payment = s.payments.find((p) => p.appointment_id === id);
      if (payment) {
        payment.status = 'approved';
        payment.approved_at = new Date().toISOString();
      }
      if (apt.payment) {
        apt.payment.status = 'approved';
        apt.payment.approved_at = new Date().toISOString();
      }
    }
  });

  const updated = getStore().appointments.find((a) => a.id === id);
  return { data: updated ? enrichAppointment(updated, getStore()) : null };
});

// POST /api/v1/appointments/:id/checkin
route('post', '/api/v1/appointments/:id/checkin', ({ params }) => {
  const id = Number(params.id);

  updateStore((s) => {
    const apt = s.appointments.find((a) => a.id === id);
    if (apt) {
      apt.status = 'checked_in';
      apt.updated_at = new Date().toISOString();
    }
  });

  const updated = getStore().appointments.find((a) => a.id === id);
  return { data: updated ? enrichAppointment(updated, getStore()) : null };
});

// POST /api/v1/appointments/:id/complete
route('post', '/api/v1/appointments/:id/complete', ({ params }) => {
  const id = Number(params.id);

  updateStore((s) => {
    const apt = s.appointments.find((a) => a.id === id);
    if (apt) {
      apt.status = 'completed';
      apt.updated_at = new Date().toISOString();
    }
  });

  const updated = getStore().appointments.find((a) => a.id === id);
  return { data: updated ? enrichAppointment(updated, getStore()) : null };
});

// POST /api/v1/appointments/checkin_by_code
route('post', '/api/v1/appointments/checkin_by_code', ({ body }) => {
  const code = (body as any)?.ticket_code;
  const store = getStore();

  const apt = store.appointments.find((a) => a.ticket_code === code);
  if (!apt) {
    throw { status: 404, message: 'Ticket no encontrado' };
  }

  updateStore((s) => {
    const a = s.appointments.find((x) => x.id === apt.id);
    if (a) {
      a.status = 'checked_in';
      a.updated_at = new Date().toISOString();
    }
  });

  const updated = getStore().appointments.find((a) => a.id === apt.id);
  return { data: updated ? enrichAppointment(updated, getStore()) : null };
});

// POST /api/v1/appointments/:id/remind_payment
route('post', '/api/v1/appointments/:id/remind_payment', () => {
  return { data: { message: 'Recordatorio de pago enviado (demo)' } };
});

function enrichAppointment(apt: Appointment, store: any): Appointment {
  return {
    ...apt,
    employee: apt.employee ?? store.employees.find((e: any) => e.id === apt.employee_id),
    service: apt.service ?? store.services.find((s: any) => s.id === apt.service_id),
    customer: apt.customer ?? store.customers.find((c: any) => c.id === apt.customer_id),
    payment: apt.payment ?? store.payments.find((p: any) => p.appointment_id === apt.id),
  };
}
