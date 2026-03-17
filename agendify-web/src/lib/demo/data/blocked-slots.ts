// ============================================================
// Agendify — Demo seed: blocked slots
// ============================================================

import type { BlockedSlot, Employee } from '@/lib/api/types';

export function seedBlockedSlots(employees: Employee[]): BlockedSlot[] {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toISOString().split('T')[0];

  const dayAfter = new Date();
  dayAfter.setDate(dayAfter.getDate() + 2);
  const dayAfterStr = dayAfter.toISOString().split('T')[0];

  return [
    {
      id: 1,
      business_id: 1,
      employee_id: employees[0]?.id ?? 1,
      date: tomorrowStr,
      start_time: '12:00',
      end_time: '13:00',
      reason: 'Almuerzo extendido',
      all_day: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    {
      id: 2,
      business_id: 1,
      employee_id: employees[1]?.id ?? 2,
      date: dayAfterStr,
      start_time: '08:00',
      end_time: '10:00',
      reason: 'Cita médica',
      all_day: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  ];
}
