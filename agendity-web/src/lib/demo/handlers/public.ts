// ============================================================
// Agendity — Demo handlers: public endpoints (booking flow)
// ============================================================

import { route } from '../router';
import { getStore, updateStore, nextId } from '../store';

function generateTicketCode(): string {
  return 'TK' + Math.random().toString(36).substring(2, 8).toUpperCase();
}

// ---------------------------------------------------------------
// Static routes MUST be registered before :slug to avoid
// the wildcard capturing "explore", "cities", etc. as a slug.
// ---------------------------------------------------------------

// GET /api/v1/public/explore
route('get', '/api/v1/public/explore', ({ query }) => {
  const store = getStore();

  return {
    data: [store.business],
    meta: {
      current_page: 1,
      total_pages: 1,
      total_count: 1,
      per_page: 20,
    },
  };
});

// GET /api/v1/public/cities
route('get', '/api/v1/public/cities', () => {
  return {
    data: [
      { name: 'Barranquilla', count: 1 },
    ],
  };
});

// GET /api/v1/public/customer_lookup
route('get', '/api/v1/public/customer_lookup', ({ query }) => {
  const store = getStore();
  const email = query.email ?? '';
  const customer = store.customers.find((c) => c.email === email);

  if (customer) {
    return { data: { name: customer.name, phone: customer.phone, email: customer.email } };
  }

  return { data: null };
});

// POST /api/v1/public/checkin_by_code
route('post', '/api/v1/public/checkin_by_code', ({ body }) => {
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
  return { data: updated };
});

// ---------------------------------------------------------------
// Dynamic :slug routes (must come AFTER static routes above)
// ---------------------------------------------------------------

// GET /api/v1/public/:slug
route('get', '/api/v1/public/:slug', ({ params }) => {
  const store = getStore();

  // Always return our demo business regardless of slug
  return {
    data: {
      business: store.business,
      services: store.services.filter((s) => s.active),
      employees: store.employees.filter((e) => e.active),
      reviews: store.reviews,
      business_hours: store.businessHours,
      average_rating: store.business.rating_average,
      total_reviews: store.business.total_reviews,
    },
  };
});

// GET /api/v1/public/:slug/availability
route('get', '/api/v1/public/:slug/availability', ({ query }) => {
  const date = query.date;
  const serviceId = Number(query.service_id);
  const store = getStore();

  const service = store.services.find((s) => s.id === serviceId);
  const duration = service?.duration_minutes ?? 30;

  // Find open hours for this day
  const dayOfWeek = new Date(date + 'T12:00:00').getDay();
  const hours = store.businessHours.find((h) => h.day_of_week === dayOfWeek);

  if (!hours || hours.closed) {
    return { data: [] };
  }

  // Generate time slots
  const [openH, openM] = hours.open_time.split(':').map(Number);
  const [closeH, closeM] = hours.close_time.split(':').map(Number);
  const openMinutes = openH * 60 + openM;
  const closeMinutes = closeH * 60 + closeM;
  const interval = store.business.slot_interval_minutes || 15;

  // Get booked slots for this date
  const booked = store.appointments
    .filter((a) => a.date === date && a.status !== 'cancelled')
    .map((a) => ({ start: a.start_time, end: a.end_time, employee_id: a.employee_id }));

  const slots: { time: string; available: boolean }[] = [];

  for (let m = openMinutes; m + duration <= closeMinutes; m += interval) {
    const time = `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`;
    const endM = m + duration;
    const endTime = `${String(Math.floor(endM / 60)).padStart(2, '0')}:${String(endM % 60).padStart(2, '0')}`;

    // Skip lunch
    if (store.business.lunch_enabled) {
      const [lsH, lsM] = store.business.lunch_start_time.split(':').map(Number);
      const [leH, leM] = store.business.lunch_end_time.split(':').map(Number);
      const lunchStart = lsH * 60 + lsM;
      const lunchEnd = leH * 60 + leM;
      if (m < lunchEnd && endM > lunchStart) {
        slots.push({ time, available: false });
        continue;
      }
    }

    // Check if any employee is available at this time
    const employeeId = query.employee_id ? Number(query.employee_id) : null;
    const relevantBookings = booked.filter((b) => {
      if (employeeId && b.employee_id !== employeeId) return false;
      const [bsH, bsM] = b.start.split(':').map(Number);
      const [beH, beM] = b.end.split(':').map(Number);
      const bStart = bsH * 60 + bsM;
      const bEnd = beH * 60 + beM;
      return m < bEnd && endM > bStart;
    });

    if (employeeId) {
      // Specific employee: check if they're free
      slots.push({ time, available: relevantBookings.length === 0 });
    } else {
      // Any employee: at least one must be free
      const busyEmployees = new Set(relevantBookings.map((b) => b.employee_id));
      const hasAvailable = store.employees.some((e) => e.active && !busyEmployees.has(e.id));
      slots.push({ time, available: hasAvailable });
    }
  }

  return { data: slots };
});

// POST /api/v1/public/:slug/book
route('post', '/api/v1/public/:slug/book', ({ body }) => {
  const data = (body as any)?.booking ?? body;
  const store = getStore();
  const now = new Date().toISOString();

  const service = store.services.find((s) => s.id === Number(data.service_id));
  const duration = service?.duration_minutes ?? 30;

  // Find available employee or use specified
  let employeeId = data.employee_id ? Number(data.employee_id) : null;
  if (!employeeId) {
    employeeId = store.employees.find((e) => e.active)?.id ?? 1;
  }
  const employee = store.employees.find((e) => e.id === employeeId);

  // Find or create customer
  const customerData = data.customer ?? {};
  let customer = store.customers.find(
    (c) => c.email === customerData.email,
  );
  if (!customer) {
    customer = {
      id: nextId('customer'),
      business_id: 1,
      name: customerData.name ?? 'Cliente',
      phone: customerData.phone ?? '',
      email: customerData.email ?? null,
      notes: null,
      total_visits: 0,
      last_visit_at: null,
      created_at: now,
      updated_at: now,
    };
    updateStore((s) => s.customers.push(customer!));
  }

  const [h, m] = (data.start_time ?? '09:00').split(':').map(Number);
  const endMinutes = h * 60 + m + duration;
  const endTime = `${String(Math.floor(endMinutes / 60)).padStart(2, '0')}:${String(endMinutes % 60).padStart(2, '0')}`;

  const ticketCode = generateTicketCode();
  const appointmentId = nextId('appointment');

  const appointment = {
    id: appointmentId,
    business_id: 1,
    employee_id: employeeId!,
    service_id: Number(data.service_id),
    customer_id: customer.id,
    date: data.date,
    start_time: data.start_time,
    end_time: endTime,
    status: 'pending_payment' as const,
    price: service?.price ?? 0,
    notes: data.notes ?? null,
    cancellation_reason: null,
    cancelled_by: null,
    ticket_code: ticketCode,
    created_at: now,
    updated_at: now,
    employee,
    service,
    customer,
  };

  updateStore((s) => {
    s.appointments.push(appointment);
  });

  return {
    data: {
      appointment,
      ticket_code: ticketCode,
      business: store.business,
    },
  };
});

// GET /api/v1/public/tickets/:code
route('get', '/api/v1/public/tickets/:code', ({ params }) => {
  const store = getStore();
  const apt = store.appointments.find((a) => a.ticket_code === params.code);

  if (!apt) {
    throw { status: 404, message: 'Ticket no encontrado' };
  }

  return {
    data: {
      appointment: {
        ...apt,
        employee: store.employees.find((e) => e.id === apt.employee_id),
        service: store.services.find((s) => s.id === apt.service_id),
        customer: store.customers.find((c) => c.id === apt.customer_id),
        payment: store.payments.find((p) => p.appointment_id === apt.id) ?? apt.payment,
      },
      business: store.business,
      ticket_vip: true,
    },
  };
});

// POST /api/v1/public/tickets/:code/cancel
route('post', '/api/v1/public/tickets/:code/cancel', ({ params, body }) => {
  const store = getStore();
  const apt = store.appointments.find((a) => a.ticket_code === params.code);

  if (!apt) {
    throw { status: 404, message: 'Ticket no encontrado' };
  }

  updateStore((s) => {
    const a = s.appointments.find((x) => x.id === apt.id);
    if (a) {
      a.status = 'cancelled';
      a.cancellation_reason = (body as any)?.reason ?? 'Cancelado por el cliente';
      a.cancelled_by = 'customer';
      a.updated_at = new Date().toISOString();
    }
  });

  const updated = getStore().appointments.find((a) => a.id === apt.id);
  return {
    data: {
      appointment: updated,
      penalty_applied: false,
      penalty_amount: 0,
    },
  };
});

// POST /api/v1/public/tickets/:code/payment
route('post', '/api/v1/public/tickets/:code/payment', ({ params }) => {
  const store = getStore();
  const apt = store.appointments.find((a) => a.ticket_code === params.code);

  if (!apt) {
    throw { status: 404, message: 'Ticket no encontrado' };
  }

  const now = new Date().toISOString();

  updateStore((s) => {
    const a = s.appointments.find((x) => x.id === apt.id);
    if (a) {
      a.status = 'payment_sent';
      a.updated_at = now;

      let payment = s.payments.find((p) => p.appointment_id === apt.id);
      if (!payment) {
        payment = {
          id: s.nextIds.payment++,
          appointment_id: apt.id,
          amount: apt.price,
          status: 'submitted',
          payment_method: 'nequi',
          reference: 'DEMO-PUB-' + apt.id,
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

      a.payment = payment;
    }
  });

  return { data: { status: 'submitted', message: 'Comprobante recibido' } };
});

// POST /api/v1/public/:slug/lock_slot
route('post', '/api/v1/public/:slug/lock_slot', () => {
  return { data: { locked: true, expires_in: 300 } };
});

// POST /api/v1/public/:slug/unlock_slot
route('post', '/api/v1/public/:slug/unlock_slot', () => {
  return { data: { unlocked: true } };
});
