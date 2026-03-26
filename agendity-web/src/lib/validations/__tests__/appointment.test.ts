import { describe, it, expect } from 'vitest';
import { createAppointmentSchema, blockSlotSchema } from '../appointment';

// ── createAppointmentSchema ──────────────────────────────────

describe('createAppointmentSchema', () => {
  const valid = {
    service_id: 1,
    employee_id: 2,
    customer_name: 'Juan Pérez',
    customer_phone: '3001234567',
    appointment_date: '2026-04-01',
    start_time: '10:00',
  };

  it('accepts valid appointment data', () => {
    expect(createAppointmentSchema.safeParse(valid).success).toBe(true);
  });

  it('accepts optional customer_email', () => {
    expect(createAppointmentSchema.safeParse({ ...valid, customer_email: 'juan@test.com' }).success).toBe(true);
  });

  it('accepts empty customer_email', () => {
    expect(createAppointmentSchema.safeParse({ ...valid, customer_email: '' }).success).toBe(true);
  });

  it('rejects invalid customer_email', () => {
    expect(createAppointmentSchema.safeParse({ ...valid, customer_email: 'bad' }).success).toBe(false);
  });

  it('accepts optional notes', () => {
    expect(createAppointmentSchema.safeParse({ ...valid, notes: 'Con barba' }).success).toBe(true);
  });

  it('rejects missing service_id', () => {
    const { service_id, ...rest } = valid;
    expect(createAppointmentSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects service_id of 0', () => {
    expect(createAppointmentSchema.safeParse({ ...valid, service_id: 0 }).success).toBe(false);
  });

  it('rejects missing employee_id', () => {
    const { employee_id, ...rest } = valid;
    expect(createAppointmentSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects missing appointment_date', () => {
    const { appointment_date, ...rest } = valid;
    expect(createAppointmentSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects phone shorter than 7 chars', () => {
    expect(createAppointmentSchema.safeParse({ ...valid, customer_phone: '123456' }).success).toBe(false);
  });
});

// ── blockSlotSchema ──────────────────────────────────────────

describe('blockSlotSchema', () => {
  const valid = {
    date: '2026-04-01',
    start_time: '12:00',
    end_time: '13:00',
  };

  it('accepts valid block slot', () => {
    expect(blockSlotSchema.safeParse(valid).success).toBe(true);
  });

  it('accepts optional employee_id', () => {
    expect(blockSlotSchema.safeParse({ ...valid, employee_id: 5 }).success).toBe(true);
  });

  it('accepts optional reason', () => {
    expect(blockSlotSchema.safeParse({ ...valid, reason: 'Almuerzo' }).success).toBe(true);
  });

  it('rejects missing date', () => {
    const { date, ...rest } = valid;
    expect(blockSlotSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects missing start_time', () => {
    const { start_time, ...rest } = valid;
    expect(blockSlotSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects missing end_time', () => {
    const { end_time, ...rest } = valid;
    expect(blockSlotSchema.safeParse(rest).success).toBe(false);
  });
});
