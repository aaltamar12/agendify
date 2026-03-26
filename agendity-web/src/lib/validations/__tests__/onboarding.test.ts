import { describe, it, expect } from 'vitest';
import {
  businessProfileSchema,
  businessHoursSchema,
  serviceSchema,
  employeeSchema,
  paymentMethodsSchema,
  cancellationPolicySchema,
} from '../onboarding';

// ── businessProfileSchema ────────────────────────────────────

describe('businessProfileSchema', () => {
  const valid = {
    name: 'Barbería Elite',
    phone: '3001234567',
    address: 'Calle 72 #45-12',
    country: 'CO',
    state: 'Atlántico',
    city: 'Barranquilla',
  };

  it('accepts valid profile data', () => {
    expect(businessProfileSchema.safeParse(valid).success).toBe(true);
  });

  it('accepts optional description', () => {
    expect(businessProfileSchema.safeParse({ ...valid, description: 'La mejor barbería' }).success).toBe(true);
  });

  it('accepts empty instagram_url', () => {
    expect(businessProfileSchema.safeParse({ ...valid, instagram_url: '' }).success).toBe(true);
  });

  it('accepts valid instagram_url', () => {
    expect(
      businessProfileSchema.safeParse({ ...valid, instagram_url: 'https://instagram.com/barberia' }).success,
    ).toBe(true);
  });

  it('rejects invalid instagram_url', () => {
    expect(businessProfileSchema.safeParse({ ...valid, instagram_url: 'not-url' }).success).toBe(false);
  });

  it('rejects missing name', () => {
    const { name, ...rest } = valid;
    expect(businessProfileSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects missing city', () => {
    const { city, ...rest } = valid;
    expect(businessProfileSchema.safeParse(rest).success).toBe(false);
  });
});

// ── businessHoursSchema ──────────────────────────────────────

describe('businessHoursSchema', () => {
  it('accepts valid hours array', () => {
    const result = businessHoursSchema.safeParse({
      hours: [
        { day_of_week: 1, open_time: '08:00', close_time: '18:00', enabled: true },
        { day_of_week: 0, open_time: '09:00', close_time: '13:00', enabled: false },
      ],
    });
    expect(result.success).toBe(true);
  });

  it('rejects day_of_week out of range', () => {
    const result = businessHoursSchema.safeParse({
      hours: [{ day_of_week: 7, open_time: '08:00', close_time: '18:00', enabled: true }],
    });
    expect(result.success).toBe(false);
  });

  it('accepts empty hours array', () => {
    expect(businessHoursSchema.safeParse({ hours: [] }).success).toBe(true);
  });
});

// ── serviceSchema ────────────────────────────────────────────

describe('serviceSchema', () => {
  const valid = { name: 'Corte clásico', price: 25000, duration_minutes: 30 };

  it('accepts valid service', () => {
    expect(serviceSchema.safeParse(valid).success).toBe(true);
  });

  it('accepts service with optional description', () => {
    expect(serviceSchema.safeParse({ ...valid, description: 'El mejor corte' }).success).toBe(true);
  });

  it('rejects missing name', () => {
    const { name, ...rest } = valid;
    expect(serviceSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects price of 0', () => {
    expect(serviceSchema.safeParse({ ...valid, price: 0 }).success).toBe(false);
  });

  it('rejects negative price', () => {
    expect(serviceSchema.safeParse({ ...valid, price: -5000 }).success).toBe(false);
  });

  it('rejects duration less than 15 minutes', () => {
    expect(serviceSchema.safeParse({ ...valid, duration_minutes: 10 }).success).toBe(false);
  });

  it('rejects duration more than 480 minutes', () => {
    expect(serviceSchema.safeParse({ ...valid, duration_minutes: 500 }).success).toBe(false);
  });

  it('accepts duration of exactly 15 minutes', () => {
    expect(serviceSchema.safeParse({ ...valid, duration_minutes: 15 }).success).toBe(true);
  });

  it('accepts duration of exactly 480 minutes', () => {
    expect(serviceSchema.safeParse({ ...valid, duration_minutes: 480 }).success).toBe(true);
  });
});

// ── employeeSchema ───────────────────────────────────────────

describe('employeeSchema', () => {
  it('accepts valid employee with just name', () => {
    expect(employeeSchema.safeParse({ name: 'Carlos' }).success).toBe(true);
  });

  it('accepts employee with optional email', () => {
    expect(employeeSchema.safeParse({ name: 'Carlos', email: 'carlos@test.com' }).success).toBe(true);
  });

  it('accepts employee with empty email string', () => {
    expect(employeeSchema.safeParse({ name: 'Carlos', email: '' }).success).toBe(true);
  });

  it('rejects invalid email', () => {
    expect(employeeSchema.safeParse({ name: 'Carlos', email: 'not-email' }).success).toBe(false);
  });

  it('rejects missing name', () => {
    expect(employeeSchema.safeParse({}).success).toBe(false);
  });
});

// ── paymentMethodsSchema ─────────────────────────────────────

describe('paymentMethodsSchema', () => {
  it('accepts all fields empty (all optional)', () => {
    expect(paymentMethodsSchema.safeParse({}).success).toBe(true);
  });

  it('accepts nequi_phone', () => {
    expect(paymentMethodsSchema.safeParse({ nequi_phone: '3001234567' }).success).toBe(true);
  });

  it('accepts daviplata_phone', () => {
    expect(paymentMethodsSchema.safeParse({ daviplata_phone: '3009876543' }).success).toBe(true);
  });

  it('accepts multiple payment methods', () => {
    expect(
      paymentMethodsSchema.safeParse({
        nequi_phone: '3001234567',
        daviplata_phone: '3009876543',
        bancolombia_account: '12345678901',
      }).success,
    ).toBe(true);
  });
});

// ── cancellationPolicySchema ─────────────────────────────────

describe('cancellationPolicySchema', () => {
  it('accepts valid policy', () => {
    expect(
      cancellationPolicySchema.safeParse({ cancellation_policy_pct: '50', cancellation_deadline_hours: 24 }).success,
    ).toBe(true);
  });

  it('accepts 0% penalty', () => {
    expect(
      cancellationPolicySchema.safeParse({ cancellation_policy_pct: '0', cancellation_deadline_hours: 2 }).success,
    ).toBe(true);
  });

  it('rejects invalid penalty percentage', () => {
    expect(
      cancellationPolicySchema.safeParse({ cancellation_policy_pct: '25', cancellation_deadline_hours: 24 }).success,
    ).toBe(false);
  });

  it('rejects deadline less than 1 hour', () => {
    expect(
      cancellationPolicySchema.safeParse({ cancellation_policy_pct: '50', cancellation_deadline_hours: 0 }).success,
    ).toBe(false);
  });

  it('rejects deadline more than 72 hours', () => {
    expect(
      cancellationPolicySchema.safeParse({ cancellation_policy_pct: '50', cancellation_deadline_hours: 100 }).success,
    ).toBe(false);
  });
});
