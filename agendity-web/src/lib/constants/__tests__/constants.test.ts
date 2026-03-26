import { describe, it, expect } from 'vitest';
import {
  getPlanSlug,
  PLAN_FEATURES,
  PLAN_DESCRIPTIONS,
  PLAN_DISPLAY,
  DYNAMIC_PRICING_GROUP_THRESHOLD,
  APPOINTMENT_STATUSES,
  PAYMENT_STATUSES,
  BUSINESS_TYPES,
  DAYS_OF_WEEK,
  ONBOARDING_STEPS,
  COLORS,
  SUPPORT_CHANNELS_BY_PLAN,
  DEFAULT_TIMEZONE,
  DEFAULT_CURRENCY,
  SLOT_DURATION_MINUTES,
  MAX_FILE_SIZE_MB,
} from '../../constants';

// ── getPlanSlug ──────────────────────────────────────────────

describe('getPlanSlug', () => {
  it('returns "basico" for "Básico"', () => {
    expect(getPlanSlug('Básico')).toBe('basico');
  });

  it('returns "profesional" for "Profesional"', () => {
    expect(getPlanSlug('Profesional')).toBe('profesional');
  });

  it('returns "inteligente" for "Inteligente"', () => {
    expect(getPlanSlug('Inteligente')).toBe('inteligente');
  });

  it('returns "trial" for unknown plan names', () => {
    expect(getPlanSlug('unknown')).toBe('trial');
  });

  it('is case insensitive', () => {
    expect(getPlanSlug('BÁSICO')).toBe('basico');
    expect(getPlanSlug('profesional')).toBe('profesional');
    expect(getPlanSlug('INTELIGENTE')).toBe('inteligente');
  });

  it('returns "trial" for empty string', () => {
    expect(getPlanSlug('')).toBe('trial');
  });
});

// ── PLAN_FEATURES ────────────────────────────────────────────

describe('PLAN_FEATURES', () => {
  it('has keys for basico, profesional, inteligente', () => {
    expect(Object.keys(PLAN_FEATURES)).toEqual(
      expect.arrayContaining(['basico', 'profesional', 'inteligente']),
    );
  });

  it('basico has features array with items', () => {
    expect(PLAN_FEATURES.basico.length).toBeGreaterThan(0);
  });

  it('profesional includes "Todo del plan Básico"', () => {
    expect(PLAN_FEATURES.profesional).toContain('Todo del plan Básico');
  });

  it('inteligente includes "Todo del plan Profesional"', () => {
    expect(PLAN_FEATURES.inteligente).toContain('Todo del plan Profesional');
  });
});

// ── PLAN_DISPLAY ─────────────────────────────────────────────

describe('PLAN_DISPLAY', () => {
  it('has entries for trial, basico, profesional, inteligente', () => {
    expect(Object.keys(PLAN_DISPLAY)).toEqual(
      expect.arrayContaining(['trial', 'basico', 'profesional', 'inteligente']),
    );
  });

  it('each entry has label, badge, bgClass, textClass', () => {
    for (const entry of Object.values(PLAN_DISPLAY)) {
      expect(entry).toHaveProperty('label');
      expect(entry).toHaveProperty('badge');
      expect(entry).toHaveProperty('bgClass');
      expect(entry).toHaveProperty('textClass');
    }
  });
});

// ── DYNAMIC_PRICING_GROUP_THRESHOLD ──────────────────────────

describe('DYNAMIC_PRICING_GROUP_THRESHOLD', () => {
  it('is 0.6', () => {
    expect(DYNAMIC_PRICING_GROUP_THRESHOLD).toBe(0.6);
  });
});

// ── Status maps ──────────────────────────────────────────────

describe('APPOINTMENT_STATUSES', () => {
  it('has all 6 appointment statuses', () => {
    const keys = Object.keys(APPOINTMENT_STATUSES);
    expect(keys).toHaveLength(6);
    expect(keys).toContain('confirmed');
    expect(keys).toContain('cancelled');
    expect(keys).toContain('completed');
  });

  it('each status has label and color', () => {
    for (const status of Object.values(APPOINTMENT_STATUSES)) {
      expect(status.label).toBeTruthy();
      expect(status.color).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });
});

describe('PAYMENT_STATUSES', () => {
  it('has 4 payment statuses', () => {
    expect(Object.keys(PAYMENT_STATUSES)).toHaveLength(4);
  });
});

// ── BUSINESS_TYPES ───────────────────────────────────────────

describe('BUSINESS_TYPES', () => {
  it('includes barbershop and salon', () => {
    expect(BUSINESS_TYPES.barbershop).toBe('Barbería');
    expect(BUSINESS_TYPES.salon).toBe('Salón de belleza');
  });
});

// ── DAYS_OF_WEEK ─────────────────────────────────────────────

describe('DAYS_OF_WEEK', () => {
  it('has 7 days', () => {
    expect(DAYS_OF_WEEK).toHaveLength(7);
  });

  it('starts with Monday (value 1)', () => {
    expect(DAYS_OF_WEEK[0].value).toBe(1);
    expect(DAYS_OF_WEEK[0].label).toBe('Lunes');
  });

  it('ends with Sunday (value 0)', () => {
    expect(DAYS_OF_WEEK[6].value).toBe(0);
    expect(DAYS_OF_WEEK[6].label).toBe('Domingo');
  });
});

// ── ONBOARDING_STEPS ─────────────────────────────────────────

describe('ONBOARDING_STEPS', () => {
  it('has 5 steps', () => {
    expect(ONBOARDING_STEPS).toHaveLength(5);
  });

  it('starts at step 1', () => {
    expect(ONBOARDING_STEPS[0].step).toBe(1);
  });

  it('ends at step 5 (payment_methods)', () => {
    expect(ONBOARDING_STEPS[4].key).toBe('payment_methods');
  });
});

// ── COLORS ───────────────────────────────────────────────────

describe('COLORS', () => {
  it('has primary color as violet', () => {
    expect(COLORS.primary).toBe('#7C3AED');
  });
});

// ── SUPPORT_CHANNELS_BY_PLAN ─────────────────────────────────

describe('SUPPORT_CHANNELS_BY_PLAN', () => {
  it('basico only gets email', () => {
    expect(SUPPORT_CHANNELS_BY_PLAN.basico).toEqual(['email']);
  });

  it('inteligente gets email, whatsapp, and chat', () => {
    expect(SUPPORT_CHANNELS_BY_PLAN.inteligente).toEqual(['email', 'whatsapp', 'chat']);
  });
});

// ── Misc constants ───────────────────────────────────────────

describe('Misc constants', () => {
  it('DEFAULT_TIMEZONE is America/Bogota', () => {
    expect(DEFAULT_TIMEZONE).toBe('America/Bogota');
  });

  it('DEFAULT_CURRENCY is COP', () => {
    expect(DEFAULT_CURRENCY).toBe('COP');
  });

  it('SLOT_DURATION_MINUTES is 30', () => {
    expect(SLOT_DURATION_MINUTES).toBe(30);
  });

  it('MAX_FILE_SIZE_MB is 5', () => {
    expect(MAX_FILE_SIZE_MB).toBe(5);
  });
});
