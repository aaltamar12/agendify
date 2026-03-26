import { describe, it, expect } from 'vitest';
import { customerInfoSchema } from '../booking';

describe('customerInfoSchema', () => {
  const valid = {
    name: 'Juan Pérez',
    email: 'juan@test.com',
    phone: '3001234567',
  };

  it('accepts valid customer data', () => {
    expect(customerInfoSchema.safeParse(valid).success).toBe(true);
  });

  it('accepts data with optional birth_date', () => {
    expect(customerInfoSchema.safeParse({ ...valid, birth_date: '1990-05-15' }).success).toBe(true);
  });

  it('accepts empty birth_date (optional)', () => {
    expect(customerInfoSchema.safeParse({ ...valid, birth_date: '' }).success).toBe(true);
  });

  it('accepts undefined birth_date (optional)', () => {
    expect(customerInfoSchema.safeParse({ ...valid, birth_date: undefined }).success).toBe(true);
  });

  it('rejects invalid birth_date format', () => {
    const result = customerInfoSchema.safeParse({ ...valid, birth_date: '15/05/1990' });
    expect(result.success).toBe(false);
  });

  it('rejects missing name', () => {
    const { name, ...rest } = valid;
    expect(customerInfoSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects empty name', () => {
    expect(customerInfoSchema.safeParse({ ...valid, name: '' }).success).toBe(false);
  });

  it('rejects single-character name', () => {
    expect(customerInfoSchema.safeParse({ ...valid, name: 'J' }).success).toBe(false);
  });

  it('rejects invalid email', () => {
    expect(customerInfoSchema.safeParse({ ...valid, email: 'not-email' }).success).toBe(false);
  });

  it('rejects empty email', () => {
    expect(customerInfoSchema.safeParse({ ...valid, email: '' }).success).toBe(false);
  });

  it('rejects phone with letters', () => {
    expect(customerInfoSchema.safeParse({ ...valid, phone: 'abc1234567' }).success).toBe(false);
  });

  it('rejects phone shorter than 10 digits', () => {
    expect(customerInfoSchema.safeParse({ ...valid, phone: '300123456' }).success).toBe(false);
  });

  it('rejects phone not starting with 3', () => {
    expect(customerInfoSchema.safeParse({ ...valid, phone: '1001234567' }).success).toBe(false);
  });

  it('accepts valid 10-digit Colombian mobile phone', () => {
    expect(customerInfoSchema.safeParse({ ...valid, phone: '3001234567' }).success).toBe(true);
    expect(customerInfoSchema.safeParse({ ...valid, phone: '3209876543' }).success).toBe(true);
  });

  it('rejects phone with 11 digits', () => {
    expect(customerInfoSchema.safeParse({ ...valid, phone: '30012345678' }).success).toBe(false);
  });
});
