// ============================================================
// Agendify — dayjs date/time helpers (America/Bogota)
// ============================================================

import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';
import isTodayPlugin from 'dayjs/plugin/isToday';
import isBetween from 'dayjs/plugin/isBetween';
import customParseFormat from 'dayjs/plugin/customParseFormat';
import 'dayjs/locale/es';

dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(isTodayPlugin);
dayjs.extend(isBetween);
dayjs.extend(customParseFormat);
dayjs.locale('es');

const TZ = 'America/Bogota';

/** Get a dayjs instance in Bogota timezone */
export function now() {
  return dayjs().tz(TZ);
}

/** Parse a date string in Bogota timezone */
export function parseDate(date: string) {
  return dayjs.tz(date, TZ);
}

/** Format: "15 de marzo de 2026" */
export function formatDate(date: string): string {
  return parseDate(date).format('D [de] MMMM [de] YYYY');
}

/** Format: "15 mar 2026" */
export function formatDateShort(date: string): string {
  return parseDate(date).format('D MMM YYYY');
}

/** Format: "3:30 PM" */
export function formatTime(time: string): string {
  return dayjs(time, 'HH:mm').format('h:mm A');
}

/** Format: "15 de marzo de 2026, 3:30 PM" */
export function formatDateTime(date: string, time?: string): string {
  if (time) {
    return `${formatDate(date)}, ${formatTime(time)}`;
  }
  return parseDate(date).format('D [de] MMMM [de] YYYY, h:mm A');
}

/** Check if a date string is today */
export function isToday(date: string): boolean {
  return parseDate(date).isToday();
}

/** Check if a date string is in the future */
export function isFuture(date: string): boolean {
  return parseDate(date).isAfter(now(), 'day');
}

/** Check if a date string is in the past */
export function isPast(date: string): boolean {
  return parseDate(date).isBefore(now(), 'day');
}

/** Get relative day label: "Hoy", "Mañana", or formatted date */
export function getRelativeDay(date: string): string {
  const d = parseDate(date);
  const today = now();
  if (d.isSame(today, 'day')) return 'Hoy';
  if (d.isSame(today.add(1, 'day'), 'day')) return 'Mañana';
  return formatDateShort(date);
}

/**
 * Generate available time slots for a given range and duration.
 *
 * @param openTime  - e.g. "08:00"
 * @param closeTime - e.g. "18:00"
 * @param durationMinutes - service duration in minutes
 * @param bookedSlots - array of { start: "HH:mm", end: "HH:mm" } already taken
 * @param date - the date string for today-awareness (skip past slots)
 */
export function getAvailableSlots(
  openTime: string,
  closeTime: string,
  durationMinutes: number,
  bookedSlots: Array<{ start: string; end: string }> = [],
  date?: string,
): string[] {
  const slots: string[] = [];
  const open = dayjs(openTime, 'HH:mm');
  const close = dayjs(closeTime, 'HH:mm');
  const currentTime = now();

  let cursor = open;

  while (cursor.add(durationMinutes, 'minute').isBefore(close) ||
         cursor.add(durationMinutes, 'minute').isSame(close)) {
    const slotStart = cursor.format('HH:mm');
    const slotEnd = cursor.add(durationMinutes, 'minute').format('HH:mm');

    // Skip past slots if date is today
    if (date && isToday(date)) {
      const slotDayjs = dayjs.tz(
        `${date} ${slotStart}`,
        'YYYY-MM-DD HH:mm',
        TZ,
      );
      if (slotDayjs.isBefore(currentTime)) {
        cursor = cursor.add(durationMinutes, 'minute');
        continue;
      }
    }

    // Check overlap with booked slots
    const isBooked = bookedSlots.some((booked) => {
      const bookedStart = dayjs(booked.start, 'HH:mm');
      const bookedEnd = dayjs(booked.end, 'HH:mm');
      const sStart = dayjs(slotStart, 'HH:mm');
      const sEnd = dayjs(slotEnd, 'HH:mm');
      return sStart.isBefore(bookedEnd) && sEnd.isAfter(bookedStart);
    });

    if (!isBooked) {
      slots.push(slotStart);
    }

    cursor = cursor.add(durationMinutes, 'minute');
  }

  return slots;
}

/** Get an array of dates for the next N days */
export function getNextDays(count: number): string[] {
  const days: string[] = [];
  for (let i = 0; i < count; i++) {
    days.push(now().add(i, 'day').format('YYYY-MM-DD'));
  }
  return days;
}

/** Get day of week (0 = Sunday, 6 = Saturday) from a date string */
export function getDayOfWeek(date: string): number {
  return parseDate(date).day();
}
