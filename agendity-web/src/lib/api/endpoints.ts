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
    uploadCover: `${BASE}/business/upload_cover`,
    coverGallery: `${BASE}/business/cover_gallery`,
    selectCover: `${BASE}/business/select_cover`,
  },

  SERVICES: {
    list: `${BASE}/services`,
    create: `${BASE}/services`,
    show: (id: number) => `${BASE}/services/${id}`,
    update: (id: number) => `${BASE}/services/${id}`,
    delete: (id: number) => `${BASE}/services/${id}`,
    categories: `${BASE}/services/categories`,
    renameCategory: `${BASE}/services/rename_category`,
    deleteCategory: `${BASE}/services/delete_category`,
  },

  EMPLOYEES: {
    list: `${BASE}/employees`,
    create: `${BASE}/employees`,
    show: (id: number) => `${BASE}/employees/${id}`,
    update: (id: number) => `${BASE}/employees/${id}`,
    delete: (id: number) => `${BASE}/employees/${id}`,
    uploadAvatar: (id: number) => `${BASE}/employees/${id}/upload_avatar`,
    invite: (id: number) => `${BASE}/employees/${id}/invite`,
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
    availableSlots: `${BASE}/appointments/available_slots`,
    cancel: (id: number) => `${BASE}/appointments/${id}/cancel`,
    complete: (id: number) => `${BASE}/appointments/${id}/complete`,
    remindPayment: (id: number) => `${BASE}/appointments/${id}/remind_payment`,
  },

  CUSTOMERS: {
    list: `${BASE}/customers`,
    show: (id: number) => `${BASE}/customers/${id}`,
    credits: (id: number) => `${BASE}/customers/${id}/credits`,
    adjustCredits: (id: number) => `${BASE}/customers/${id}/credits/adjust`,
    creditBalance: (id: number) => `${BASE}/customers/${id}/credit_balance`,
    sendBirthdayGreeting: (id: number) => `${BASE}/customers/${id}/send_birthday_greeting`,
  },

  CREDITS: {
    summary: `${BASE}/credits/summary`,
    bulkAdjust: `${BASE}/credits/bulk_adjust`,
  },

  RECONCILIATION: {
    check: `${BASE}/reconciliation/check`,
  },

  EMPLOYEE_BALANCE: {
    adjust: (id: number) => `${BASE}/employees/${id}/adjust_balance`,
    history: (id: number) => `${BASE}/employees/${id}/balance_history`,
  },

  GOALS: {
    list: `${BASE}/goals`,
    create: `${BASE}/goals`,
    update: (id: number) => `${BASE}/goals/${id}`,
    delete: (id: number) => `${BASE}/goals/${id}`,
    progress: `${BASE}/goals/progress`,
  },

  DYNAMIC_PRICING: {
    list: `${BASE}/dynamic_pricing`,
    create: `${BASE}/dynamic_pricing`,
    update: (id: number) => `${BASE}/dynamic_pricing/${id}`,
    accept: (id: number) => `${BASE}/dynamic_pricing/${id}/accept`,
    reject: (id: number) => `${BASE}/dynamic_pricing/${id}/reject`,
    delete: (id: number) => `${BASE}/dynamic_pricing/${id}`,
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

  CASH_REGISTER: {
    today: `${BASE}/cash_register/today`,
    close: `${BASE}/cash_register/close`,
    history: `${BASE}/cash_register/history`,
    show: (id: number) => `${BASE}/cash_register/${id}`,
    uploadProof: `${BASE}/cash_register/upload_proof`,
    deleteProof: `${BASE}/cash_register/delete_proof`,
    employeePaymentReceipt: (closeId: number, paymentId: number) =>
      `${BASE}/cash_register/${closeId}/employee_payments/${paymentId}/receipt`,
  },

  EMPLOYEE_INVITATIONS: {
    show: (token: string) => `${BASE}/employee_invitations/${token}`,
    accept: (token: string) => `${BASE}/employee_invitations/${token}/accept`,
  },

  EMPLOYEE_PORTAL: {
    dashboard: `${BASE}/employee/dashboard`,
    score: `${BASE}/employee/score`,
    appointments: `${BASE}/employee/appointments`,
    checkin: (id: number) => `${BASE}/employee/appointments/${id}/checkin`,
    checkinByCode: `${BASE}/employee/checkin_by_code`,
  },

  REPORTS: {
    summary: `${BASE}/reports/summary`,
    revenue: `${BASE}/reports/revenue`,
    topServices: `${BASE}/reports/top_services`,
    topEmployees: `${BASE}/reports/top_employees`,
    frequentCustomers: `${BASE}/reports/frequent_customers`,
    profit: `${BASE}/reports/profit`,
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

  NOTIFICATION_CONFIG: {
    list: `${BASE}/notification_config`,
  },

  DISCOUNT_CODES: {
    list: `${BASE}/discount_codes`,
    create: `${BASE}/discount_codes`,
    show: (id: number) => `${BASE}/discount_codes/${id}`,
    update: (id: number) => `${BASE}/discount_codes/${id}`,
    delete: (id: number) => `${BASE}/discount_codes/${id}`,
  },

  ADMIN: {
    businesses: `${BASE}/admin/businesses`,
    impersonate: `${BASE}/admin/impersonate`,
    stopImpersonation: `${BASE}/admin/stop_impersonation`,
  },

  SUBSCRIPTION: {
    plans: `${BASE}/subscription/plans`,
    paymentInfo: `${BASE}/subscription/payment_info`,
    checkout: `${BASE}/subscription/checkout`,
    status: `${BASE}/subscription/status`,
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
    cancelPreview: (code: string) => `${BASE}/public/tickets/${code}/cancel_preview`,
    submitTicketPayment: (code: string) => `${BASE}/public/tickets/${code}/payment`,
    explore: `${BASE}/public/explore`,
    pricePreview: (slug: string) => `${BASE}/public/${slug}/price_preview`,
    priceCalendar: (slug: string) => `${BASE}/public/${slug}/price_calendar`,
    plans: `${BASE}/public/plans`,
    siteConfig: `${BASE}/public/site_config`,
    adBanners: `${BASE}/public/ad_banners`,
    adBannerImpression: (id: number) => `${BASE}/public/ad_banners/${id}/impression`,
    adBannerClick: (id: number) => `${BASE}/public/ad_banners/${id}/click`,
    validateCode: (slug: string) => `${BASE}/public/${slug}/validate_code`,
    rate: (slug: string) => `${BASE}/public/${slug}/rate`,
    createReview: (slug: string) => `${BASE}/public/${slug}/reviews`,
  },
} as const;
