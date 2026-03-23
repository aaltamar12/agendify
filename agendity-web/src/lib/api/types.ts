// ============================================================
// Agendity — TypeScript interfaces matching DB schema
// ============================================================

// --- Status & enum union types ---

export type AppointmentStatus =
  | 'pending_payment'
  | 'payment_sent'
  | 'confirmed'
  | 'checked_in'
  | 'cancelled'
  | 'completed';

export type PaymentStatus =
  | 'pending'
  | 'submitted'
  | 'approved'
  | 'rejected';

export type BusinessStatus =
  | 'active'
  | 'inactive'
  | 'suspended';

export type SubscriptionStatus =
  | 'trialing'
  | 'active'
  | 'past_due'
  | 'cancelled'
  | 'expired';

export type BusinessType =
  | 'barbershop'
  | 'salon'
  | 'spa'
  | 'nails'
  | 'other';

export type UserRole =
  | 'owner'
  | 'admin'
  | 'employee';

export type DayOfWeek = 0 | 1 | 2 | 3 | 4 | 5 | 6;

// --- Core models ---

export interface User {
  id: number;
  email: string;
  name: string;
  phone: string | null;
  role: UserRole;
  avatar_url: string | null;
  business_id: number | null;
  created_at: string;
  updated_at: string;
}

export interface Business {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  business_type: BusinessType;
  phone: string | null;
  email: string | null;
  address: string | null;
  city: string | null;
  state: string | null;
  country: string;
  latitude: number | null;
  longitude: number | null;
  logo_url: string | null;
  cover_url: string | null;
  cover_source: string | null;
  primary_color: string;
  secondary_color: string;
  currency: string;
  timezone: string;
  status: BusinessStatus;
  onboarding_completed: boolean;
  rating_average: number;
  total_reviews: number;
  instagram_url: string | null;
  facebook_url: string | null;
  website_url: string | null;
  google_maps_url: string | null;
  cancellation_policy_pct: number;
  cancellation_deadline_hours: number;
  lunch_start_time: string;
  lunch_end_time: string;
  lunch_enabled: boolean;
  slot_interval_minutes: number;
  gap_between_appointments_minutes: number;
  nequi_phone: string | null;
  daviplata_phone: string | null;
  bancolombia_account: string | null;
  cashback_enabled?: boolean;
  cashback_percentage?: number;
  cancellation_refund_as_credit?: boolean;
  owner_id: number;
  created_at: string;
  updated_at: string;
  // True when this is an independent professional (no physical establishment)
  independent?: boolean;
  // Legal fields (admin-managed)
  nit?: string | null;
  legal_representative_name?: string | null;
  legal_representative_document?: string | null;
  legal_representative_document_type?: string | null;
  // True when business has Profesional+ plan with featured listing
  featured?: boolean;
  // True when business has a plan with ai_features (verified badge in explore)
  verified?: boolean;
  // Included via serializer association
  current_subscription?: Subscription | null;
}

export interface Employee {
  id: number;
  business_id: number;
  user_id: number | null;
  name: string;
  email: string | null;
  phone: string | null;
  avatar_url: string | null;
  bio: string | null;
  active: boolean;
  payment_type?: 'manual' | 'commission' | 'fixed_daily';
  commission_percentage: number | null;
  fixed_daily_pay?: number | null;
  document_number?: string | null;
  document_type?: string | null;
  fiscal_address?: string | null;
  has_account?: boolean;
  pending_balance?: number;
  score?: number | null;
  rating_avg?: number | null;
  created_at: string;
  updated_at: string;
}

export interface Service {
  id: number;
  business_id: number;
  name: string;
  description: string | null;
  duration_minutes: number;
  price: number;
  active: boolean;
  category: string | null;
  image_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface EmployeeService {
  id: number;
  employee_id: number;
  service_id: number;
  custom_duration: number | null;
  custom_price: number | null;
  created_at: string;
  updated_at: string;
}

export interface Customer {
  id: number;
  business_id: number;
  name: string;
  phone: string;
  email: string | null;
  notes: string | null;
  total_visits: number;
  last_visit_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Appointment {
  id: number;
  business_id: number;
  employee_id: number;
  service_id: number;
  customer_id: number;
  date: string;
  appointment_date?: string;
  start_time: string;
  end_time: string;
  status: AppointmentStatus;
  price: number;
  notes: string | null;
  cancellation_reason: string | null;
  cancelled_by: 'business' | 'customer' | null;
  ticket_code: string | null;
  created_at: string;
  updated_at: string;
  original_price?: number;
  credits_applied?: number;
  dynamic_pricing_id?: number | null;
  checked_in_by_type?: string | null;
  checked_in_by_id?: number | null;
  checkin_substitute?: boolean;
  // Expanded relations (optional, included via serializer)
  employee?: Employee;
  service?: Service;
  customer?: Customer;
  payment?: Payment;
  appointment_services?: AppointmentService[];
}

export interface Payment {
  id: number;
  appointment_id: number;
  amount: number;
  status: PaymentStatus;
  payment_method: string | null;
  reference: string | null;
  proof_url: string | null;
  submitted_at: string | null;
  approved_at: string | null;
  rejected_at: string | null;
  rejection_reason: string | null;
  created_at: string;
  updated_at: string;
}

export interface AppointmentService {
  id: number;
  appointment_id?: number;
  service_id: number;
  employee_id?: number;
  service_name?: string;
  price: number;
  duration_minutes?: number;
  service?: Service;
  employee?: Employee;
}

export interface Review {
  id: number;
  appointment_id: number;
  customer_id: number;
  business_id: number;
  employee_id: number;
  rating: number;
  comment: string | null;
  created_at: string;
  updated_at: string;
  customer?: Customer;
}

export interface BusinessHour {
  id: number;
  business_id: number;
  day_of_week: DayOfWeek;
  open_time: string;
  close_time: string;
  closed: boolean;
  created_at: string;
  updated_at: string;
}

export interface EmployeeSchedule {
  id: number;
  employee_id: number;
  day_of_week: DayOfWeek;
  start_time: string;
  end_time: string;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface BlockedSlot {
  id: number;
  business_id: number;
  employee_id: number | null;
  date: string;
  start_time: string;
  end_time: string;
  reason: string | null;
  all_day: boolean;
  created_at: string;
  updated_at: string;
}

export interface Subscription {
  id: number;
  business_id: number;
  plan_id: number;
  status: SubscriptionStatus;
  start_date: string;
  end_date: string;
  current_period_start?: string;
  current_period_end?: string;
  trial_end?: string | null;
  cancelled_at?: string | null;
  created_at: string;
  updated_at: string;
  plan?: Plan;
}

export interface Plan {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  price_monthly: number;
  price_monthly_usd?: number | null;
  price_yearly?: number;
  currency?: string;
  max_employees?: number;
  max_services?: number;
  features?: string[];
  active?: boolean;
  created_at: string;
  updated_at: string;
}

export interface DiscountCode {
  id: number;
  business_id: number;
  code: string;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  max_uses: number | null;
  current_uses: number;
  valid_from: string;
  valid_until: string | null;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface BusinessQR {
  id: number;
  business_id: number;
  qr_url: string;
  short_url: string;
  scan_count: number;
  created_at: string;
  updated_at: string;
}

export interface AnalyticsEvent {
  id: number;
  business_id: number;
  event_type: string;
  event_data: Record<string, unknown>;
  source: string | null;
  created_at: string;
}

export interface AIInsight {
  id: number;
  business_id: number;
  insight_type: string;
  title: string;
  description: string;
  data: Record<string, unknown>;
  read: boolean;
  created_at: string;
  updated_at: string;
}

export interface AIPrediction {
  id: number;
  business_id: number;
  prediction_type: string;
  prediction_data: Record<string, unknown>;
  confidence: number;
  period_start: string;
  period_end: string;
  created_at: string;
  updated_at: string;
}

export type NotificationType =
  | 'new_booking'
  | 'payment_submitted'
  | 'payment_approved'
  | 'booking_cancelled'
  | 'reminder';

export interface Notification {
  id: number;
  title: string;
  body: string | null;
  notification_type: NotificationType;
  link: string | null;
  read: boolean;
  created_at: string;
}

// --- API response wrappers ---

export interface ApiResponse<T> {
  data: T;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    current_page: number;
    total_pages: number;
    total_count: number;
    per_page: number;
  };
}
