import { describe, it, expect } from 'vitest';
import { formatName, formatDuration, getInitials } from '../format';

// ── formatName ───────────────────────────────────────────────

describe('formatName', () => {
  it('capitalizes each word', () => {
    expect(formatName('juan pérez')).toBe('Juan Pérez');
  });

  it('trims whitespace', () => {
    expect(formatName('  carlos  ')).toBe('Carlos');
  });

  it('handles multiple spaces between words', () => {
    expect(formatName('ana   maria')).toBe('Ana Maria');
  });

  it('lowercases then capitalizes', () => {
    expect(formatName('JUAN PÉREZ')).toBe('Juan Pérez');
  });
});

// ── formatDuration ───────────────────────────────────────────

describe('formatDuration', () => {
  it('formats minutes under 60 as "X min"', () => {
    expect(formatDuration(30)).toBe('30 min');
  });

  it('formats exactly 60 as "1h"', () => {
    expect(formatDuration(60)).toBe('1h');
  });

  it('formats 90 as "1h 30min"', () => {
    expect(formatDuration(90)).toBe('1h 30min');
  });

  it('formats 120 as "2h"', () => {
    expect(formatDuration(120)).toBe('2h');
  });

  it('formats 150 as "2h 30min"', () => {
    expect(formatDuration(150)).toBe('2h 30min');
  });
});

// ── getInitials ──────────────────────────────────────────────

describe('getInitials', () => {
  it('returns two initials from full name', () => {
    expect(getInitials('Juan Pérez')).toBe('JP');
  });

  it('returns one initial for single name', () => {
    expect(getInitials('Carlos')).toBe('C');
  });

  it('returns max 2 initials for three names', () => {
    expect(getInitials('Ana María López')).toBe('AM');
  });

  it('handles leading/trailing spaces', () => {
    expect(getInitials('  Juan Pérez  ')).toBe('JP');
  });
});
