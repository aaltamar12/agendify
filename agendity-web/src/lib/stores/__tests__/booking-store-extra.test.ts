import { describe, it, expect, beforeEach } from 'vitest';
import { useBookingStore } from '../booking-store';
import type { Service } from '@/lib/api/types';

const makeService = (overrides: Partial<Service> = {}): Service => ({
  id: 1,
  business_id: 1,
  name: 'Corte clásico',
  description: null,
  duration_minutes: 30,
  price: 25000,
  active: true,
  category: 'cortes',
  image_url: null,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
  ...overrides,
});

describe('useBookingStore — extended', () => {
  beforeEach(() => {
    useBookingStore.getState().reset();
  });

  // ── toggleService: category replacement ──

  it('replaces service of the same category', () => {
    const s1 = makeService({ id: 1, category: 'cortes', name: 'Corte 1' });
    const s2 = makeService({ id: 2, category: 'cortes', name: 'Corte 2' });

    useBookingStore.getState().toggleService(s1);
    useBookingStore.getState().toggleService(s2);

    const services = useBookingStore.getState().selectedServices;
    expect(services).toHaveLength(1);
    expect(services[0].id).toBe(2);
  });

  it('allows services from different categories simultaneously', () => {
    const s1 = makeService({ id: 1, category: 'cortes' });
    const s2 = makeService({ id: 2, category: 'barba' });

    useBookingStore.getState().toggleService(s1);
    useBookingStore.getState().toggleService(s2);

    expect(useBookingStore.getState().selectedServices).toHaveLength(2);
  });

  it('selectedService is always the first in the array', () => {
    const s1 = makeService({ id: 1, category: 'cortes' });
    const s2 = makeService({ id: 2, category: 'barba' });

    useBookingStore.getState().toggleService(s1);
    useBookingStore.getState().toggleService(s2);

    // withoutSameCategory keeps s1 (different category), then appends s2 → [s1, s2]
    // selectedService = newServices[0] = s1
    expect(useBookingStore.getState().selectedService?.id).toBe(1);
  });

  it('sets selectedService to null when all toggled off', () => {
    const s1 = makeService({ id: 1 });
    useBookingStore.getState().toggleService(s1);
    useBookingStore.getState().toggleService(s1); // toggle off
    expect(useBookingStore.getState().selectedService).toBeNull();
  });

  // ── Dynamic pricing ──

  it('setDynamicPricing stores pricing info', () => {
    const pricing = {
      base_price: 25000,
      adjusted_price: 22000,
      adjustment_pct: -12,
      dynamic_pricing_name: 'Descuento lunes',
      is_discount: true,
      has_dynamic_pricing: true,
    };

    useBookingStore.getState().setDynamicPricing(pricing);
    expect(useBookingStore.getState().dynamicPricing).toEqual(pricing);
  });

  it('setDynamicPricing can be cleared with null', () => {
    useBookingStore.getState().setDynamicPricing({
      base_price: 25000,
      adjusted_price: 22000,
      adjustment_pct: -12,
      dynamic_pricing_name: null,
      is_discount: true,
      has_dynamic_pricing: true,
    });
    useBookingStore.getState().setDynamicPricing(null);
    expect(useBookingStore.getState().dynamicPricing).toBeNull();
  });

  // ── Credit balance ──

  it('setCreditBalance updates balance', () => {
    useBookingStore.getState().setCreditBalance(5000);
    expect(useBookingStore.getState().creditBalance).toBe(5000);
  });

  it('credit balance resets to 0', () => {
    useBookingStore.getState().setCreditBalance(5000);
    useBookingStore.getState().reset();
    expect(useBookingStore.getState().creditBalance).toBe(0);
  });

  // ── Discount ──

  it('setDiscount stores code, amount, and name', () => {
    useBookingStore.getState().setDiscount('PROMO10', 10000, 'Promo Marzo');
    const state = useBookingStore.getState();
    expect(state.discountCode).toBe('PROMO10');
    expect(state.discountAmount).toBe(10000);
    expect(state.discountName).toBe('Promo Marzo');
  });

  it('clearDiscount resets discount fields', () => {
    useBookingStore.getState().setDiscount('PROMO10', 10000, 'Promo Marzo');
    useBookingStore.getState().clearDiscount();
    const state = useBookingStore.getState();
    expect(state.discountCode).toBeNull();
    expect(state.discountAmount).toBe(0);
    expect(state.discountName).toBeNull();
  });

  it('reset clears discount too', () => {
    useBookingStore.getState().setDiscount('PROMO10', 10000, 'Promo Marzo');
    useBookingStore.getState().reset();
    expect(useBookingStore.getState().discountCode).toBeNull();
  });

  // ── setStep ──

  it('setStep sets arbitrary step', () => {
    useBookingStore.getState().setStep(4);
    expect(useBookingStore.getState().currentStep).toBe(4);
  });
});
