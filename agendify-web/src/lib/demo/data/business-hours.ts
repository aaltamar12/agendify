// ============================================================
// Agendify — Demo seed: business hours
// ============================================================

import type { BusinessHour, DayOfWeek } from '@/lib/api/types';

const now = '2026-03-15T10:00:00Z';

export function seedBusinessHours(): BusinessHour[] {
  // Mon-Sat 8:00-19:00, Sunday closed
  const days: { day: DayOfWeek; closed: boolean }[] = [
    { day: 0, closed: true },  // Sunday
    { day: 1, closed: false }, // Monday
    { day: 2, closed: false }, // Tuesday
    { day: 3, closed: false }, // Wednesday
    { day: 4, closed: false }, // Thursday
    { day: 5, closed: false }, // Friday
    { day: 6, closed: false }, // Saturday
  ];

  return days.map((d, i) => ({
    id: i + 1,
    business_id: 1,
    day_of_week: d.day,
    open_time: d.closed ? '08:00' : '08:00',
    close_time: d.closed ? '19:00' : '19:00',
    closed: d.closed,
    created_at: now,
    updated_at: now,
  }));
}
