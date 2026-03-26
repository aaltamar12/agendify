import { describe, it, expect } from 'vitest';
import {
  loginSchema,
  registerSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from '../auth';

// ── loginSchema ──────────────────────────────────────────────

describe('loginSchema', () => {
  const validLogin = {
    email: 'owner@barberia.co',
    password: 'secret123',
  };

  it('accepts valid login data', () => {
    expect(loginSchema.safeParse(validLogin).success).toBe(true);
  });

  it('rejects missing email', () => {
    const result = loginSchema.safeParse({ password: 'secret123' });
    expect(result.success).toBe(false);
  });

  it('rejects empty email', () => {
    const result = loginSchema.safeParse({ email: '', password: 'secret123' });
    expect(result.success).toBe(false);
  });

  it('rejects invalid email format', () => {
    const result = loginSchema.safeParse({ email: 'not-an-email', password: 'secret123' });
    expect(result.success).toBe(false);
  });

  it('rejects missing password', () => {
    const result = loginSchema.safeParse({ email: 'test@test.com' });
    expect(result.success).toBe(false);
  });

  it('rejects password shorter than 6 characters', () => {
    const result = loginSchema.safeParse({ email: 'test@test.com', password: '12345' });
    expect(result.success).toBe(false);
  });

  it('accepts password with exactly 6 characters', () => {
    const result = loginSchema.safeParse({ email: 'test@test.com', password: '123456' });
    expect(result.success).toBe(true);
  });
});

// ── registerSchema ───────────────────────────────────────────

describe('registerSchema', () => {
  const validRegister = {
    name: 'Alfonso Test',
    email: 'alfonso@agendity.co',
    password: 'password123',
    passwordConfirmation: 'password123',
    businessName: 'Mi Barbería',
    businessType: 'barbershop' as const,
    termsAccepted: true as const,
  };

  it('accepts valid registration data', () => {
    expect(registerSchema.safeParse(validRegister).success).toBe(true);
  });

  it('accepts optional referralCode', () => {
    const result = registerSchema.safeParse({ ...validRegister, referralCode: 'ABC123' });
    expect(result.success).toBe(true);
  });

  it('rejects missing name', () => {
    const { name, ...rest } = validRegister;
    expect(registerSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects empty name', () => {
    expect(registerSchema.safeParse({ ...validRegister, name: '' }).success).toBe(false);
  });

  it('rejects invalid email', () => {
    expect(registerSchema.safeParse({ ...validRegister, email: 'bad' }).success).toBe(false);
  });

  it('rejects short password (< 6 chars)', () => {
    expect(
      registerSchema.safeParse({ ...validRegister, password: '123', passwordConfirmation: '123' }).success,
    ).toBe(false);
  });

  it('rejects password mismatch', () => {
    const result = registerSchema.safeParse({
      ...validRegister,
      passwordConfirmation: 'different',
    });
    expect(result.success).toBe(false);
  });

  it('rejects missing businessName', () => {
    const { businessName, ...rest } = validRegister;
    expect(registerSchema.safeParse(rest).success).toBe(false);
  });

  it('rejects empty businessName', () => {
    expect(registerSchema.safeParse({ ...validRegister, businessName: '' }).success).toBe(false);
  });

  it('rejects invalid businessType', () => {
    expect(
      registerSchema.safeParse({ ...validRegister, businessType: 'gym' }).success,
    ).toBe(false);
  });

  it('rejects termsAccepted = false', () => {
    expect(
      registerSchema.safeParse({ ...validRegister, termsAccepted: false }).success,
    ).toBe(false);
  });

  it('rejects missing termsAccepted', () => {
    const { termsAccepted, ...rest } = validRegister;
    expect(registerSchema.safeParse(rest).success).toBe(false);
  });

  it('accepts all valid businessType values', () => {
    const types = ['barbershop', 'salon', 'spa', 'nails', 'estetica', 'consultorio', 'other'] as const;
    for (const t of types) {
      expect(registerSchema.safeParse({ ...validRegister, businessType: t }).success).toBe(true);
    }
  });
});

// ── forgotPasswordSchema ─────────────────────────────────────

describe('forgotPasswordSchema', () => {
  it('accepts valid email', () => {
    expect(forgotPasswordSchema.safeParse({ email: 'user@test.com' }).success).toBe(true);
  });

  it('rejects empty email', () => {
    expect(forgotPasswordSchema.safeParse({ email: '' }).success).toBe(false);
  });

  it('rejects invalid email', () => {
    expect(forgotPasswordSchema.safeParse({ email: 'not-email' }).success).toBe(false);
  });
});

// ── resetPasswordSchema ──────────────────────────────────────

describe('resetPasswordSchema', () => {
  it('accepts valid matching passwords (min 6 chars)', () => {
    expect(
      resetPasswordSchema.safeParse({ password: 'newpas', passwordConfirmation: 'newpas' }).success,
    ).toBe(true);
  });

  it('rejects password shorter than 6 characters', () => {
    expect(
      resetPasswordSchema.safeParse({ password: '12345', passwordConfirmation: '12345' }).success,
    ).toBe(false);
  });

  it('rejects mismatched passwords', () => {
    const result = resetPasswordSchema.safeParse({
      password: 'newpass88',
      passwordConfirmation: 'different',
    });
    expect(result.success).toBe(false);
  });

  it('rejects empty confirmation', () => {
    const result = resetPasswordSchema.safeParse({
      password: 'newpass88',
      passwordConfirmation: '',
    });
    expect(result.success).toBe(false);
  });
});
