// ============================================================
// Agendify — Booking flow store (public booking)
// ============================================================

import { create } from 'zustand';
import type { Service, Employee } from '@/lib/api/types';

export interface CustomerInfo {
  name: string;
  phone: string;
  email?: string;
  notes?: string;
}

interface BookingState {
  currentStep: number;
  selectedServices: Service[];
  selectedService: Service | null; // Derived: first of selectedServices
  selectedEmployee: Employee | null;
  selectedDate: string | null;
  selectedTime: string | null;
  customerInfo: CustomerInfo | null;

  // Actions
  toggleService: (service: Service) => void;
  setEmployee: (employee: Employee | null) => void;
  setDateTime: (date: string, time: string) => void;
  setCustomerInfo: (info: CustomerInfo) => void;
  setStep: (step: number) => void;
  nextStep: () => void;
  prevStep: () => void;
  reset: () => void;
}

const INITIAL_STATE = {
  currentStep: 1,
  selectedServices: [] as Service[],
  selectedService: null as Service | null,
  selectedEmployee: null,
  selectedDate: null,
  selectedTime: null,
  customerInfo: null,
};

export const useBookingStore = create<BookingState>()((set, get) => ({
  ...INITIAL_STATE,

  // selectedService is derived — use useBookingStore(s => s.selectedServices[0]) in components

  // Toggle a service: one per category max
  toggleService: (service) =>
    set((state) => {
      const category = service.category || 'general';
      const alreadySelected = state.selectedServices.find((s) => s.id === service.id);

      let newServices: Service[];
      if (alreadySelected) {
        newServices = state.selectedServices.filter((s) => s.id !== service.id);
      } else {
        const withoutSameCategory = state.selectedServices.filter(
          (s) => (s.category || 'general') !== category
        );
        newServices = [...withoutSameCategory, service];
      }
      return { selectedServices: newServices, selectedService: newServices[0] ?? null };
    }),

  setEmployee: (employee) => set({ selectedEmployee: employee }),

  setDateTime: (date, time) =>
    set({ selectedDate: date, selectedTime: time }),

  setCustomerInfo: (info) => set({ customerInfo: info }),

  setStep: (step) => set({ currentStep: step }),

  nextStep: () =>
    set((state) => ({
      currentStep: Math.min(state.currentStep + 1, 5),
    })),

  prevStep: () =>
    set((state) => ({
      currentStep: Math.max(state.currentStep - 1, 1),
    })),

  reset: () => set(INITIAL_STATE),
}));
