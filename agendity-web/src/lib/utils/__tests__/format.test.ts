import { describe, it, expect } from 'vitest';
import { formatCurrency, formatPhone, truncate, capitalize } from '../format';

describe('formatCurrency', () => {
  it('formats a number as COP', () => {
    expect(formatCurrency(50000)).toBe('$50.000');
  });

  it('handles zero', () => {
    expect(formatCurrency(0)).toBe('$0');
  });

  it('handles decimals by rounding', () => {
    expect(formatCurrency(25000.75)).toBe('$25.001');
  });

  it('formats large numbers', () => {
    expect(formatCurrency(1500000)).toBe('$1.500.000');
  });
});

describe('formatPhone', () => {
  it('formats a 10-digit Colombian number', () => {
    expect(formatPhone('3001234567')).toBe('300 123 4567');
  });

  it('strips country code 57', () => {
    expect(formatPhone('573001234567')).toBe('300 123 4567');
  });

  it('returns the original string for invalid lengths', () => {
    expect(formatPhone('12345')).toBe('12345');
  });
});

describe('truncate', () => {
  it('returns the original string if shorter than limit', () => {
    expect(truncate('hello', 10)).toBe('hello');
  });

  it('truncates at the limit and adds "..."', () => {
    expect(truncate('hello world', 5)).toBe('hello...');
  });

  it('handles exact length', () => {
    expect(truncate('hello', 5)).toBe('hello');
  });
});

describe('capitalize', () => {
  it('capitalizes the first letter', () => {
    expect(capitalize('hola')).toBe('Hola');
  });

  it('returns empty string for empty input', () => {
    expect(capitalize('')).toBe('');
  });

  it('does not change already capitalized strings', () => {
    expect(capitalize('Hola')).toBe('Hola');
  });
});
