// ============================================================
// Agendity — Application constants
// ============================================================

import type {
  AppointmentStatus,
  PaymentStatus,
  BusinessStatus,
  SubscriptionStatus,
  BusinessType,
  DayOfWeek,
} from './api/types';

// --- Appointment statuses ---

export const APPOINTMENT_STATUSES: Record<
  AppointmentStatus,
  { label: string; color: string }
> = {
  pending_payment: { label: 'Pendiente de pago', color: '#F59E0B' },
  payment_sent: { label: 'Pago enviado', color: '#3B82F6' },
  confirmed: { label: 'Confirmada', color: '#10B981' },
  checked_in: { label: 'En atención', color: '#7C3AED' },
  cancelled: { label: 'Cancelada', color: '#EF4444' },
  completed: { label: 'Completada', color: '#6B7280' },
};

// --- Payment statuses ---

export const PAYMENT_STATUSES: Record<
  PaymentStatus,
  { label: string; color: string }
> = {
  pending: { label: 'Pendiente', color: '#F59E0B' },
  submitted: { label: 'Enviado', color: '#3B82F6' },
  approved: { label: 'Aprobado', color: '#10B981' },
  rejected: { label: 'Rechazado', color: '#EF4444' },
};

// --- Business statuses ---

export const BUSINESS_STATUSES: Record<
  BusinessStatus,
  { label: string; color: string }
> = {
  active: { label: 'Activo', color: '#10B981' },
  inactive: { label: 'Inactivo', color: '#6B7280' },
  suspended: { label: 'Suspendido', color: '#EF4444' },
};

// --- Subscription statuses ---

export const SUBSCRIPTION_STATUSES: Record<
  SubscriptionStatus,
  { label: string; color: string }
> = {
  trialing: { label: 'Prueba gratis', color: '#3B82F6' },
  active: { label: 'Activa', color: '#10B981' },
  past_due: { label: 'Pago vencido', color: '#F59E0B' },
  cancelled: { label: 'Cancelada', color: '#EF4444' },
  expired: { label: 'Expirada', color: '#6B7280' },
};

// --- Business types ---

export const BUSINESS_TYPES: Record<BusinessType, string> = {
  barbershop: 'Barbería',
  salon: 'Salón de belleza',
  spa: 'Spa',
  nails: 'Uñas',
  other: 'Otro',
};

// --- Days of week (Monday-first, Spanish labels) ---

export const DAYS_OF_WEEK: { value: DayOfWeek; label: string; short: string }[] = [
  { value: 1, label: 'Lunes', short: 'Lun' },
  { value: 2, label: 'Martes', short: 'Mar' },
  { value: 3, label: 'Miércoles', short: 'Mié' },
  { value: 4, label: 'Jueves', short: 'Jue' },
  { value: 5, label: 'Viernes', short: 'Vie' },
  { value: 6, label: 'Sábado', short: 'Sáb' },
  { value: 0, label: 'Domingo', short: 'Dom' },
];

// --- Onboarding steps ---

export const ONBOARDING_STEPS = [
  { step: 1, key: 'business_info', label: 'Información del negocio' },
  { step: 2, key: 'services', label: 'Servicios' },
  { step: 3, key: 'employees', label: 'Empleados' },
  { step: 4, key: 'schedule', label: 'Horario' },
  { step: 5, key: 'payment_methods', label: 'Métodos de pago' },
] as const;

// --- Theme colors ---

export const COLORS = {
  primary: '#7C3AED',
  primaryLight: '#A78BFA',
  primaryDark: '#5B21B6',
  secondary: '#000000',
  success: '#10B981',
  warning: '#F59E0B',
  danger: '#EF4444',
  info: '#3B82F6',
} as const;

// --- Plan slugs & display config ---

export type PlanSlug = 'basico' | 'profesional' | 'inteligente' | 'trial';

export const PLAN_DISPLAY: Record<PlanSlug, { label: string; badge: string; bgClass: string; textClass: string }> = {
  trial: { label: 'Trial', badge: 'Trial', bgClass: 'bg-blue-100', textClass: 'text-blue-700' },
  basico: { label: 'Básico', badge: 'Básico', bgClass: 'bg-gray-100', textClass: 'text-gray-600' },
  profesional: { label: 'Profesional', badge: 'Profesional', bgClass: 'bg-violet-100', textClass: 'text-violet-700' },
  inteligente: { label: 'Inteligente', badge: 'Inteligente', bgClass: 'bg-amber-100', textClass: 'text-amber-700' },
};

// Features restricted by plan. Key = nav item href, value = minimum plan required.
export const PLAN_RESTRICTED_FEATURES: Record<string, PlanSlug[]> = {
  // These nav items are locked for Básico plan users
  '/dashboard/reviews': ['profesional', 'inteligente'],
};

// Features that show a lock icon + tooltip for specific plans
export const PLAN_FEATURE_LOCKS: Record<string, { requiredPlans: PlanSlug[]; tooltip: string }> = {
  '/dashboard/reviews': {
    requiredPlans: ['profesional', 'inteligente'],
    tooltip: 'Disponible en Plan Profesional',
  },
  '/dashboard/cash-register': {
    requiredPlans: ['profesional', 'inteligente'],
    tooltip: 'Disponible en Plan Profesional',
  },
  '/dashboard/dynamic-pricing': {
    requiredPlans: ['profesional', 'inteligente'],
    tooltip: 'Disponible en Plan Profesional',
  },
  '/dashboard/reconciliation': {
    requiredPlans: ['inteligente'],
    tooltip: 'Disponible en Plan Inteligente',
  },
};

// Advanced reports lock (Básico gets basic reports, but advanced are locked)
export const ADVANCED_REPORTS_PLANS: PlanSlug[] = ['profesional', 'inteligente'];

// Brand customization lock (logo + colors)
export const BRAND_CUSTOMIZATION_PLANS: PlanSlug[] = ['profesional', 'inteligente'];

// AI features lock
export const AI_FEATURES_PLANS: PlanSlug[] = ['inteligente'];

// --- Support config ---

export const SUPPORT_CONFIG = {
  email: 'soporte@agendity.com',
  whatsapp: '+573001234567',
  whatsappUrl: 'https://wa.me/573001234567',
};

export const SUPPORT_CHANNELS_BY_PLAN: Record<PlanSlug, string[]> = {
  basico: ['email'],
  profesional: ['email', 'whatsapp'],
  inteligente: ['email', 'whatsapp', 'chat'],
  trial: ['email', 'whatsapp'],
};

// --- Misc ---

export const DEFAULT_TIMEZONE = 'America/Bogota';
export const DEFAULT_CURRENCY = 'COP';
export const DEFAULT_COUNTRY = 'CO';
export const DEFAULT_LOCALE = 'es-CO';
export const SLOT_DURATION_MINUTES = 30;
export const MAX_FILE_SIZE_MB = 5;
