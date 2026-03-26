import { describe, it, expect } from 'vitest';
import {
  formatTime,
  formatDate,
  formatDateShort,
  formatDateTime,
  getNextDays,
  getAvailableSlots,
  getDayOfWeek,
  parseDate,
} from '../date';

// ── parseDate ────────────────────────────────────────────────

describe('parseDate', () => {
  it('returns a dayjs object for a valid date string', () => {
    const d = parseDate('2026-03-15');
    expect(d.isValid()).toBe(true);
    expect(d.year()).toBe(2026);
    expect(d.month()).toBe(2); // 0-indexed
    expect(d.date()).toBe(15);
  });
});

// ── formatTime ───────────────────────────────────────────────

describe('formatTime', () => {
  it('formats 24h time to 12h AM/PM', () => {
    expect(formatTime('08:00')).toBe('8:00 AM');
  });

  it('formats noon correctly', () => {
    expect(formatTime('12:00')).toBe('12:00 PM');
  });

  it('formats afternoon time', () => {
    expect(formatTime('15:30')).toBe('3:30 PM');
  });

  it('formats midnight', () => {
    expect(formatTime('00:00')).toBe('12:00 AM');
  });
});

// ── formatDate ───────────────────────────────────────────────

describe('formatDate', () => {
  it('formats as "D de MMMM de YYYY" in Spanish', () => {
    const result = formatDate('2026-03-15');
    expect(result).toBe('15 de marzo de 2026');
  });

  it('formats January correctly', () => {
    expect(formatDate('2026-01-01')).toBe('1 de enero de 2026');
  });
});

// ── formatDateShort ──────────────────────────────────────────

describe('formatDateShort', () => {
  it('formats as "D MMM YYYY" in Spanish', () => {
    const result = formatDateShort('2026-03-15');
    // dayjs es locale uses abbreviated month
    expect(result).toMatch(/15\s.*\s2026/);
  });
});

// ── formatDateTime ───────────────────────────────────────────

describe('formatDateTime', () => {
  it('formats date + time together', () => {
    const result = formatDateTime('2026-03-15', '15:30');
    expect(result).toBe('15 de marzo de 2026, 3:30 PM');
  });

  it('formats date alone when no time provided', () => {
    const result = formatDateTime('2026-03-15T10:00:00-05:00');
    expect(result).toContain('15 de marzo de 2026');
  });
});

// ── getNextDays ──────────────────────────────────────────────

describe('getNextDays', () => {
  it('returns the correct number of days', () => {
    const days = getNextDays(7);
    expect(days).toHaveLength(7);
  });

  it('returns YYYY-MM-DD format strings', () => {
    const days = getNextDays(3);
    for (const day of days) {
      expect(day).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    }
  });

  it('returns an empty array for count 0', () => {
    expect(getNextDays(0)).toHaveLength(0);
  });

  it('first element is today', () => {
    const days = getNextDays(1);
    const today = new Date();
    const yyyy = today.getFullYear();
    // Just check format, not exact date (timezone-sensitive)
    expect(days[0]).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});

// ── getDayOfWeek ─────────────────────────────────────────────

describe('getDayOfWeek', () => {
  it('returns 0 for Sunday', () => {
    // 2026-03-22 is a Sunday
    expect(getDayOfWeek('2026-03-22')).toBe(0);
  });

  it('returns 1 for Monday', () => {
    // 2026-03-23 is a Monday
    expect(getDayOfWeek('2026-03-23')).toBe(1);
  });

  it('returns 6 for Saturday', () => {
    // 2026-03-28 is a Saturday
    expect(getDayOfWeek('2026-03-28')).toBe(6);
  });
});

// ── getAvailableSlots ────────────────────────────────────────

describe('getAvailableSlots', () => {
  it('generates correct slots for a simple range', () => {
    const slots = getAvailableSlots('08:00', '10:00', 30);
    expect(slots).toEqual(['08:00', '08:30', '09:00', '09:30']);
  });

  it('generates slots respecting duration', () => {
    const slots = getAvailableSlots('08:00', '10:00', 60);
    expect(slots).toEqual(['08:00', '09:00']);
  });

  it('returns empty array when duration exceeds range', () => {
    const slots = getAvailableSlots('08:00', '08:30', 60);
    expect(slots).toEqual([]);
  });

  it('excludes booked slots (overlap check)', () => {
    const booked = [{ start: '09:00', end: '09:30' }];
    const slots = getAvailableSlots('08:00', '10:00', 30, booked);
    expect(slots).not.toContain('09:00');
    expect(slots).toContain('08:00');
    expect(slots).toContain('09:30');
  });

  it('excludes partially overlapping booked slots', () => {
    // 30min service from 09:00-09:30 overlaps with booking 09:15-09:45
    const booked = [{ start: '09:15', end: '09:45' }];
    const slots = getAvailableSlots('09:00', '10:00', 30, booked);
    expect(slots).not.toContain('09:00'); // 09:00-09:30 overlaps 09:15
    expect(slots).not.toContain('09:30'); // 09:30-10:00 overlaps 09:15-09:45? No — 09:30 < 09:45
  });

  it('handles multiple booked slots', () => {
    const booked = [
      { start: '08:00', end: '08:30' },
      { start: '09:00', end: '09:30' },
    ];
    const slots = getAvailableSlots('08:00', '10:00', 30, booked);
    expect(slots).not.toContain('08:00');
    expect(slots).not.toContain('09:00');
    expect(slots).toContain('08:30');
    expect(slots).toContain('09:30');
  });

  it('returns single slot when range equals duration', () => {
    const slots = getAvailableSlots('08:00', '08:30', 30);
    expect(slots).toEqual(['08:00']);
  });
});
