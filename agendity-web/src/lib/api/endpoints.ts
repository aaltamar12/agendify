// ============================================================
// Agendity — Centralized API endpoint map
// ============================================================

const BASE = '/api/v1';

export const ENDPOINTS = {
  AUTH: {
    login: `${BASE}/auth/login`,
    register: `${BASE}/auth/register`,
    refresh: `${BASE}/auth/refresh`,
    me: `${BASE}/auth/me`,
    logout: `${BASE}/auth/logout`,
    forgotPassword: `${BASE}/auth/forgot_password`,
    resetPassword: `${BASE}/auth/reset_password`,
  },

  BUSINESS: {
    current: `${BASE}/business`,
    onboarding: `${BASE}/business/onboarding`,
    uploadLogo: `${BASE}/business/upload_logo`,
  },

  SERVICES: {
    list: `${BASE}/services`,
    create: `${BASE}/services`,
    show: (id: number) => `${BASE}/services/${id}`,
    update: (id: number) => `${BASE}/services/${id}`,
    delete: (id: number) => `${BASE}/services/${id}`,
  },

  EMPLOYEES: {
    list: `${BASE}/employees`,
    create: `${BASE}/employees`,
    show: (id: number) => `${BASE}/employees/${id}`,
    update: (id: number) => `${BASE}/employees/${id}`,
    delete: (id: number) => `${BASE}/employees/${id}`,
    uploadAvatar: (id: number) => `${BASE}/employees/${id}/upload_avatar`,
  },

  APPOINTMENTS: {
    list: `${BASE}/appointments`,
    create: `${BASE}/appointments`,
    show: (id: number) => `${BASE}/appointments/${id}`,
    update: (id: number) => `${BASE}/appointments/${id}`,
    delete: (id: number) => `${BASE}/appointments/${id}`,
    confirm: (id: number) => `${BASE}/appointments/${id}/confirm`,
    checkin: (id: number) => `${BASE}/appointments/${id}/checkin`,
    checkinByCode: `${BASE}/appointments/checkin_by_code`,
    cancel: (id: number) => `${BASE}/appointments/${id}/cancel`,
    complete: (id: number) => `${BASE}/appointments/${id}/complete`,
    remindPayment: (id: number) => `${BASE}/appointments/${id}/remind_payment`,
  },

  CUSTOMERS: {
    list: `${BASE}/customers`,
    show: (id: number) => `${BASE}/customers/${id}`,
  },

  PAYMENTS: {
    submit: (appointmentId: number) =>
      `${BASE}/appointments/${appointmentId}/payments/submit`,
    approve: (paymentId: number) => `${BASE}/payments/${paymentId}/approve`,
    reject: (paymentId: number) => `${BASE}/payments/${paymentId}/reject`,
  },

  REVIEWS: {
    list: `${BASE}/reviews`,
  },

  BUSINESS_HOURS: {
    show: `${BASE}/business_hours`,
    update: `${BASE}/business_hours`,
  },

  BLOCKED_SLOTS: {
    list: `${BASE}/blocked_slots`,
    create: `${BASE}/blocked_slots`,
    show: (id: number) => `${BASE}/blocked_slots/${id}`,
    update: (id: number) => `${BASE}/blocked_slots/${id}`,
    delete: (id: number) => `${BASE}/blocked_slots/${id}`,
  },

  REPORTS: {
    summary: `${BASE}/reports/summary`,
    revenue: `${BASE}/reports/revenue`,
    topServices: `${BASE}/reports/top_services`,
    topEmployees: `${BASE}/reports/top_employees`,
    frequentCustomers: `${BASE}/reports/frequent_customers`,
  },

  QR: {
    generate: `${BASE}/qr/generate`,
  },

  NOTIFICATIONS: {
    list: `${BASE}/notifications`,
    unreadCount: `${BASE}/notifications/unread_count`,
    markRead: (id: number) => `${BASE}/notifications/${id}/mark_read`,
    markAllRead: `${BASE}/notifications/mark_all_read`,
  },

  ADMIN: {
    businesses: `${BASE}/admin/businesses`,
    impersonate: `${BASE}/admin/impersonate`,
    stopImpersonation: `${BASE}/admin/stop_impersonation`,
  },

  LOCATIONS: {
    countries: `${BASE}/locations/countries`,
    states: `${BASE}/locations/states`,
    cities: `${BASE}/locations/cities`,
  },

  PUBLIC: {
    business: (slug: string) => `${BASE}/public/${slug}`,
    availability: (slug: string) => `${BASE}/public/${slug}/availability`,
    book: (slug: string) => `${BASE}/public/${slug}/book`,
    ticket: (code: string) => `${BASE}/public/tickets/${code}`,
    cancelTicket: (code: string) => `${BASE}/public/tickets/${code}/cancel`,
    submitTicketPayment: (code: string) => `${BASE}/public/tickets/${code}/payment`,
    explore: `${BASE}/public/explore`,
  },
} as const;
