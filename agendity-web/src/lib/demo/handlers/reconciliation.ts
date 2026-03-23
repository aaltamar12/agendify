// ============================================================
// Agendity — Demo handlers: reconciliation
// ============================================================

import { route } from '../router';
import { getStore } from '../store';

// GET /api/v1/reconciliation/check
route('get', '/api/v1/reconciliation/check', () => {
  const store = getStore();
  const today = new Date().toISOString().split('T')[0];

  // Find today's appointments that are completed
  const todayCompleted = store.appointments.filter(
    (a) => a.date === today && a.status === 'completed',
  );

  // Find payments for today's completed appointments
  const todayPayments = store.payments.filter((p) =>
    todayCompleted.some((a) => a.id === p.appointment_id),
  );

  const totalExpected = todayCompleted.reduce((sum, a) => sum + a.price, 0);
  const totalReceived = todayPayments
    .filter((p) => p.status === 'approved')
    .reduce((sum, p) => sum + p.amount, 0);

  const pendingPayments = store.payments.filter((p) => p.status === 'submitted');

  return {
    data: {
      date: today,
      total_expected: totalExpected,
      total_received: totalReceived,
      difference: totalReceived - totalExpected,
      is_balanced: totalReceived === totalExpected,
      pending_approvals: pendingPayments.length,
      pending_amount: pendingPayments.reduce((sum, p) => sum + p.amount, 0),
      completed_appointments: todayCompleted.length,
      paid_appointments: todayPayments.filter((p) => p.status === 'approved').length,
      discrepancies: totalReceived !== totalExpected
        ? [
            {
              type: 'amount_mismatch',
              message: `Diferencia de ${Math.abs(totalReceived - totalExpected).toLocaleString('es-CO')} COP`,
              expected: totalExpected,
              actual: totalReceived,
            },
          ]
        : [],
    },
  };
});
