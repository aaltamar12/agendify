// ============================================================
// Agendity — Demo seed: appointments + payments
// ============================================================

import type { Appointment, Payment, Service, Employee, Customer, AppointmentStatus } from '@/lib/api/types';

function generateTicketCode(): string {
  return 'TK' + Math.random().toString(36).substring(2, 8).toUpperCase();
}

function daysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().split('T')[0];
}

function daysFromNow(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d.toISOString().split('T')[0];
}

function today(): string {
  return new Date().toISOString().split('T')[0];
}

function isoNow(): string {
  return new Date().toISOString();
}

interface AppointmentSeed {
  id: number;
  serviceIdx: number;
  employeeIdx: number;
  customerIdx: number;
  date: string;
  startTime: string;
  status: AppointmentStatus;
  hasPayment: boolean;
}

export function seedAppointments(
  services: Service[],
  employees: Employee[],
  customers: Customer[],
): { appointments: Appointment[]; payments: Payment[] } {
  const seeds: AppointmentSeed[] = [
    // 10 completed (last 30 days)
    { id: 1, serviceIdx: 0, employeeIdx: 0, customerIdx: 0, date: daysAgo(28), startTime: '09:00', status: 'completed', hasPayment: true },
    { id: 2, serviceIdx: 1, employeeIdx: 1, customerIdx: 2, date: daysAgo(25), startTime: '10:00', status: 'completed', hasPayment: true },
    { id: 3, serviceIdx: 2, employeeIdx: 1, customerIdx: 4, date: daysAgo(22), startTime: '11:00', status: 'completed', hasPayment: true },
    { id: 4, serviceIdx: 0, employeeIdx: 2, customerIdx: 6, date: daysAgo(20), startTime: '14:00', status: 'completed', hasPayment: true },
    { id: 5, serviceIdx: 3, employeeIdx: 3, customerIdx: 7, date: daysAgo(18), startTime: '15:00', status: 'completed', hasPayment: true },
    { id: 6, serviceIdx: 1, employeeIdx: 0, customerIdx: 9, date: daysAgo(15), startTime: '09:30', status: 'completed', hasPayment: true },
    { id: 7, serviceIdx: 4, employeeIdx: 2, customerIdx: 10, date: daysAgo(12), startTime: '10:00', status: 'completed', hasPayment: true },
    { id: 8, serviceIdx: 0, employeeIdx: 0, customerIdx: 12, date: daysAgo(8), startTime: '16:00', status: 'completed', hasPayment: true },
    { id: 9, serviceIdx: 5, employeeIdx: 1, customerIdx: 14, date: daysAgo(5), startTime: '11:00', status: 'completed', hasPayment: true },
    { id: 10, serviceIdx: 2, employeeIdx: 1, customerIdx: 3, date: daysAgo(2), startTime: '14:00', status: 'completed', hasPayment: true },

    // 5 confirmed (next 7 days)
    { id: 11, serviceIdx: 0, employeeIdx: 0, customerIdx: 0, date: daysFromNow(1), startTime: '09:00', status: 'confirmed', hasPayment: true },
    { id: 12, serviceIdx: 1, employeeIdx: 1, customerIdx: 4, date: daysFromNow(1), startTime: '10:00', status: 'confirmed', hasPayment: true },
    { id: 13, serviceIdx: 2, employeeIdx: 2, customerIdx: 2, date: daysFromNow(2), startTime: '11:00', status: 'confirmed', hasPayment: true },
    { id: 14, serviceIdx: 3, employeeIdx: 3, customerIdx: 7, date: daysFromNow(3), startTime: '15:00', status: 'confirmed', hasPayment: true },
    { id: 15, serviceIdx: 0, employeeIdx: 0, customerIdx: 12, date: daysFromNow(5), startTime: '16:00', status: 'confirmed', hasPayment: true },

    // 3 pending_payment
    { id: 16, serviceIdx: 1, employeeIdx: 1, customerIdx: 1, date: daysFromNow(1), startTime: '14:00', status: 'pending_payment', hasPayment: false },
    { id: 17, serviceIdx: 4, employeeIdx: 2, customerIdx: 5, date: daysFromNow(2), startTime: '09:00', status: 'pending_payment', hasPayment: false },
    { id: 18, serviceIdx: 0, employeeIdx: 0, customerIdx: 8, date: daysFromNow(3), startTime: '10:00', status: 'pending_payment', hasPayment: false },

    // 3 payment_sent (awaiting approval)
    { id: 19, serviceIdx: 2, employeeIdx: 1, customerIdx: 10, date: daysFromNow(1), startTime: '16:00', status: 'payment_sent', hasPayment: true },
    { id: 20, serviceIdx: 5, employeeIdx: 0, customerIdx: 13, date: daysFromNow(2), startTime: '15:00', status: 'payment_sent', hasPayment: true },
    { id: 21, serviceIdx: 1, employeeIdx: 3, customerIdx: 11, date: daysFromNow(4), startTime: '10:00', status: 'payment_sent', hasPayment: true },

    // 2 checked_in (today)
    { id: 22, serviceIdx: 0, employeeIdx: 0, customerIdx: 4, date: today(), startTime: '09:00', status: 'checked_in', hasPayment: true },
    { id: 23, serviceIdx: 1, employeeIdx: 1, customerIdx: 14, date: today(), startTime: '09:30', status: 'checked_in', hasPayment: true },

    // 2 cancelled
    { id: 24, serviceIdx: 2, employeeIdx: 2, customerIdx: 3, date: daysFromNow(1), startTime: '11:00', status: 'cancelled', hasPayment: false },
    { id: 25, serviceIdx: 0, employeeIdx: 0, customerIdx: 6, date: daysAgo(3), startTime: '14:00', status: 'cancelled', hasPayment: false },

    // 2 more today (confirmed, for agenda visibility)
    { id: 26, serviceIdx: 6, employeeIdx: 2, customerIdx: 9, date: today(), startTime: '11:00', status: 'confirmed', hasPayment: true },
    { id: 27, serviceIdx: 7, employeeIdx: 3, customerIdx: 1, date: today(), startTime: '14:00', status: 'confirmed', hasPayment: true },
  ];

  const appointments: Appointment[] = [];
  const payments: Payment[] = [];

  for (const s of seeds) {
    const service = services[s.serviceIdx];
    const employee = employees[s.employeeIdx];
    const customer = customers[s.customerIdx];

    if (!service || !employee || !customer) continue;

    // Calculate end time
    const [h, m] = s.startTime.split(':').map(Number);
    const endMinutes = h * 60 + m + service.duration_minutes;
    const endTime = `${String(Math.floor(endMinutes / 60)).padStart(2, '0')}:${String(endMinutes % 60).padStart(2, '0')}`;

    const isCancelled = s.status === 'cancelled';

    const appointment: Appointment = {
      id: s.id,
      business_id: 1,
      employee_id: employee.id,
      service_id: service.id,
      customer_id: customer.id,
      date: s.date,
      start_time: s.startTime,
      end_time: endTime,
      status: s.status,
      price: service.price,
      notes: null,
      cancellation_reason: isCancelled ? 'No puedo asistir' : null,
      cancelled_by: isCancelled ? 'customer' : null,
      ticket_code: generateTicketCode(),
      created_at: isoNow(),
      updated_at: isoNow(),
      employee,
      service,
      customer,
    };

    if (s.hasPayment) {
      const paymentStatus =
        s.status === 'completed' || s.status === 'confirmed' || s.status === 'checked_in'
          ? 'approved'
          : s.status === 'payment_sent'
            ? 'submitted'
            : 'pending';

      const payment: Payment = {
        id: s.id,
        appointment_id: s.id,
        amount: service.price,
        status: paymentStatus as Payment['status'],
        payment_method: paymentStatus !== 'pending' ? 'nequi' : null,
        reference: paymentStatus === 'submitted' ? 'REF-' + s.id : null,
        proof_url: paymentStatus === 'submitted' ? '/demo-proof.jpg' : null,
        submitted_at: paymentStatus !== 'pending' ? isoNow() : null,
        approved_at: paymentStatus === 'approved' ? isoNow() : null,
        rejected_at: null,
        rejection_reason: null,
        created_at: isoNow(),
        updated_at: isoNow(),
      };

      payments.push(payment);
      appointment.payment = payment;
    }

    appointments.push(appointment);
  }

  return { appointments, payments };
}

export function seedPayments(): Payment[] {
  // Payments are created alongside appointments
  return [];
}
