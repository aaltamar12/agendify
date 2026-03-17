// ============================================================
// Agendify — Demo mode in-memory store with localStorage persistence
// ============================================================

import type {
  User,
  Business,
  Employee,
  Service,
  Customer,
  Appointment,
  Payment,
  Review,
  BusinessHour,
  BlockedSlot,
  Notification,
  Subscription,
  Plan,
} from '@/lib/api/types';

import { seedUser, seedBusiness, seedSubscription, seedPlan } from './data/business';
import { seedServices } from './data/services';
import { seedEmployees } from './data/employees';
import { seedAppointments, seedPayments } from './data/appointments';
import { seedCustomers } from './data/customers';
import { seedReviews } from './data/reviews';
import { seedNotifications } from './data/notifications';
import { seedBusinessHours } from './data/business-hours';
import { seedBlockedSlots } from './data/blocked-slots';

const STORAGE_KEY = 'agendify-demo-store';

export interface DemoStore {
  user: User;
  business: Business;
  subscription: Subscription;
  plan: Plan;
  services: Service[];
  employees: Employee[];
  customers: Customer[];
  appointments: Appointment[];
  payments: Payment[];
  reviews: Review[];
  notifications: Notification[];
  businessHours: BusinessHour[];
  blockedSlots: BlockedSlot[];

  // Auto-increment counters
  nextIds: {
    service: number;
    employee: number;
    customer: number;
    appointment: number;
    payment: number;
    notification: number;
    blockedSlot: number;
    review: number;
  };
}

let store: DemoStore | null = null;

function createFreshStore(): DemoStore {
  const services = seedServices();
  const employees = seedEmployees();
  const customers = seedCustomers();
  const { appointments, payments } = seedAppointments(services, employees, customers);
  const reviews = seedReviews(customers, employees);
  const notifications = seedNotifications();
  const businessHours = seedBusinessHours();
  const blockedSlots = seedBlockedSlots(employees);

  return {
    user: seedUser(),
    business: seedBusiness(),
    subscription: seedSubscription(),
    plan: seedPlan(),
    services,
    employees,
    customers,
    appointments,
    payments,
    reviews,
    notifications,
    businessHours,
    blockedSlots,
    nextIds: {
      service: 100,
      employee: 100,
      customer: 100,
      appointment: 100,
      payment: 100,
      notification: 100,
      blockedSlot: 100,
      review: 100,
    },
  };
}

/**
 * Initialize store: restore from localStorage or create fresh.
 */
export function initStore(): void {
  if (typeof window === 'undefined') return;

  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      store = JSON.parse(saved);
      console.log('[DEMO] Store restored from localStorage');
      return;
    }
  } catch {
    // Corrupted data — start fresh
  }

  store = createFreshStore();
  persistStore();
  console.log('[DEMO] Store initialized with seed data');
}

/**
 * Persist current store to localStorage.
 */
export function persistStore(): void {
  if (!store || typeof window === 'undefined') return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(store));
  } catch {
    console.warn('[DEMO] Failed to persist store to localStorage');
  }
}

/**
 * Get the current store (throws if not initialized).
 */
export function getStore(): DemoStore {
  if (!store) {
    throw new Error('[DEMO] Store not initialized. Call initStore() first.');
  }
  return store;
}

/**
 * Update store and persist.
 */
export function updateStore(updater: (s: DemoStore) => void): void {
  const s = getStore();
  updater(s);
  persistStore();
}

/**
 * Get next auto-increment ID for an entity.
 */
export function nextId(entity: keyof DemoStore['nextIds']): number {
  const s = getStore();
  const id = s.nextIds[entity]++;
  persistStore();
  return id;
}

/**
 * Reset store to fresh seed data.
 */
export function resetStore(): void {
  store = createFreshStore();
  persistStore();
  console.log('[DEMO] Store reset to seed data');
}
