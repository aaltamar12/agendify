// ============================================================
// Agendify — Demo seed: business, user, subscription
// ============================================================

import type { User, Business, Subscription, Plan } from '@/lib/api/types';

export function seedUser(): User {
  return {
    id: 1,
    email: 'demo@agendify.co',
    name: 'Carlos Mendoza',
    phone: '+573001234567',
    role: 'owner',
    avatar_url: null,
    business_id: 1,
    created_at: '2025-11-01T10:00:00Z',
    updated_at: '2026-03-15T10:00:00Z',
  };
}

export function seedPlan(): Plan {
  return {
    id: 2,
    name: 'Profesional',
    slug: 'profesional',
    description: 'Plan completo para negocios en crecimiento',
    price_monthly: 50000,
    price_yearly: 480000,
    currency: 'COP',
    max_employees: 10,
    max_services: 20,
    features: [
      'online_booking',
      'advanced_reports',
      'employee_management',
      'ticket_vip',
      'brand_customization',
      'featured_listing',
      'whatsapp_notifications',
    ],
    active: true,
    created_at: '2025-01-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
  };
}

export function seedSubscription(): Subscription {
  return {
    id: 1,
    business_id: 1,
    plan_id: 2,
    status: 'active',
    current_period_start: '2026-03-01T00:00:00Z',
    current_period_end: '2026-03-31T23:59:59Z',
    trial_end: null,
    cancelled_at: null,
    created_at: '2025-11-01T10:00:00Z',
    updated_at: '2026-03-01T00:00:00Z',
    plan: seedPlan(),
  };
}

export function seedBusiness(): Business {
  return {
    id: 1,
    name: 'Barbería Elite',
    slug: 'barberia-elite',
    description:
      'La mejor barbería de Barranquilla. Estilo, precisión y actitud. Más de 5 años de experiencia transformando tu imagen.',
    business_type: 'barbershop',
    phone: '+573001234567',
    email: 'contacto@barberiaelite.co',
    address: 'Calle 84 #52-10, Local 3',
    city: 'Barranquilla',
    state: 'ATL',
    country: 'CO',
    latitude: 10.9878,
    longitude: -74.7889,
    logo_url: null,
    cover_url: null,
    primary_color: '#7c3aed',
    secondary_color: '#1e1b4b',
    currency: 'COP',
    timezone: 'America/Bogota',
    status: 'active',
    onboarding_completed: true,
    rating_average: 4.7,
    total_reviews: 10,
    instagram_url: 'https://instagram.com/barberiaelite',
    facebook_url: 'https://facebook.com/barberiaelite',
    website_url: null,
    google_maps_url: 'https://maps.google.com/?q=10.9878,-74.7889',
    cancellation_policy_pct: 50,
    cancellation_deadline_hours: 4,
    lunch_start_time: '12:00',
    lunch_end_time: '13:00',
    lunch_enabled: true,
    slot_interval_minutes: 15,
    gap_between_appointments_minutes: 0,
    nequi_phone: '3001234567',
    daviplata_phone: '3001234567',
    bancolombia_account: '12345678901',
    owner_id: 1,
    created_at: '2025-11-01T10:00:00Z',
    updated_at: '2026-03-15T10:00:00Z',
    featured: true,
    current_subscription: seedSubscription(),
  };
}
