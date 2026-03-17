import { describe, it, expect, beforeEach } from 'vitest';
import { useBookingStore } from '../booking-store';
import type { Service, Employee } from '@/lib/api/types';

const mockService: Service = {
  id: 1,
  business_id: 1,
  name: 'Corte clásico',
  description: 'Corte de cabello clásico',
  duration_minutes: 30,
  price: 25000,
  active: true,
  category: 'cortes',
  image_url: null,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
};

const mockEmployee: Employee = {
  id: 1,
  business_id: 1,
  user_id: 2,
  name: 'Carlos Pérez',
  email: 'carlos@test.co',
  phone: '3009876543',
  avatar_url: null,
  bio: null,
  active: true,
  commission_percentage: 40,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
};

describe('useBookingStore', () => {
  beforeEach(() => {
    useBookingStore.getState().reset();
  });

  it('has correct initial state', () => {
    const state = useBookingStore.getState();
    expect(state.currentStep).toBe(1);
    expect(state.selectedServices).toHaveLength(0);
    expect(state.selectedEmployee).toBeNull();
    expect(state.selectedDate).toBeNull();
    expect(state.selectedTime).toBeNull();
    expect(state.customerInfo).toBeNull();
  });

  it('setService sets the service without advancing step', () => {
    useBookingStore.getState().toggleService(mockService);

    const state = useBookingStore.getState();
    expect(state.selectedServices[0]).toEqual(mockService);
    expect(state.currentStep).toBe(1); // No auto-advance
  });

  it('setService toggles off when clicking the same service', () => {
    useBookingStore.getState().toggleService(mockService);
    expect(useBookingStore.getState().selectedServices[0]).toEqual(mockService);

    useBookingStore.getState().toggleService(mockService);
    expect(useBookingStore.getState().selectedServices).toHaveLength(0);
  });

  it('setEmployee sets the employee without advancing step', () => {
    useBookingStore.getState().setEmployee(mockEmployee);

    const state = useBookingStore.getState();
    expect(state.selectedEmployee).toEqual(mockEmployee);
    expect(state.currentStep).toBe(1); // No auto-advance
  });

  it('setDateTime sets date/time without advancing step', () => {
    useBookingStore.getState().setDateTime('2025-06-15', '10:00');

    const state = useBookingStore.getState();
    expect(state.selectedDate).toBe('2025-06-15');
    expect(state.selectedTime).toBe('10:00');
    expect(state.currentStep).toBe(1); // No auto-advance
  });

  it('setCustomerInfo sets customer info without advancing step', () => {
    useBookingStore
      .getState()
      .setCustomerInfo({ name: 'Juan', phone: '3001234567' });

    const state = useBookingStore.getState();
    expect(state.customerInfo).toEqual({ name: 'Juan', phone: '3001234567' });
    expect(state.currentStep).toBe(1); // No auto-advance — nextStep() is called separately
  });

  it('reset returns to initial state', () => {
    useBookingStore.getState().toggleService(mockService);
    useBookingStore.getState().setEmployee(mockEmployee);
    useBookingStore.getState().setDateTime('2025-06-15', '10:00');
    useBookingStore.getState().reset();

    const state = useBookingStore.getState();
    expect(state.currentStep).toBe(1);
    expect(state.selectedServices).toHaveLength(0);
    expect(state.selectedEmployee).toBeNull();
    expect(state.selectedDate).toBeNull();
    expect(state.selectedTime).toBeNull();
  });

  it('nextStep increments step by 1 (max 5)', () => {
    useBookingStore.getState().nextStep();
    expect(useBookingStore.getState().currentStep).toBe(2);

    useBookingStore.getState().setStep(5);
    useBookingStore.getState().nextStep();
    expect(useBookingStore.getState().currentStep).toBe(5);
  });

  it('prevStep decrements step by 1 (min 1)', () => {
    useBookingStore.getState().setStep(3);
    useBookingStore.getState().prevStep();
    expect(useBookingStore.getState().currentStep).toBe(2);

    useBookingStore.getState().setStep(1);
    useBookingStore.getState().prevStep();
    expect(useBookingStore.getState().currentStep).toBe(1);
  });
});
