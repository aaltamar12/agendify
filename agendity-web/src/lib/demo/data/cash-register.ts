// ============================================================
// Agendity — Demo seed: cash register
// ============================================================

export interface CashRegisterSummary {
  date: string;
  total_revenue: number;
  total_appointments: number;
  completed_appointments: number;
  cancelled_appointments: number;
  payment_methods: {
    nequi: number;
    daviplata: number;
    cash: number;
    bancolombia: number;
  };
  employee_breakdown: {
    employee_id: number;
    employee_name: string;
    total_revenue: number;
    commission_percentage: number;
    commission_amount: number;
    appointments_count: number;
  }[];
  is_closed: boolean;
  closed_at: string | null;
  closed_by_id: number | null;
}

export interface CashRegisterClose {
  id: number;
  business_id: number;
  date: string;
  total_revenue: number;
  total_commission: number;
  employee_payments: {
    employee_id: number;
    employee_name: string;
    commission_amount: number;
    paid: boolean;
  }[];
  notes: string | null;
  closed_at: string;
  closed_by_id: number;
}

function today(): string {
  return new Date().toISOString().split('T')[0];
}

function daysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().split('T')[0];
}

export function seedTodaySummary(): CashRegisterSummary {
  return {
    date: today(),
    total_revenue: 95000,
    total_appointments: 6,
    completed_appointments: 2,
    cancelled_appointments: 0,
    payment_methods: {
      nequi: 45000,
      daviplata: 25000,
      cash: 15000,
      bancolombia: 10000,
    },
    employee_breakdown: [
      {
        employee_id: 1,
        employee_name: 'Carlos Méndez',
        total_revenue: 30000,
        commission_percentage: 0,
        commission_amount: 0,
        appointments_count: 2,
      },
      {
        employee_id: 2,
        employee_name: 'Juan Camilo Herrera',
        total_revenue: 25000,
        commission_percentage: 40,
        commission_amount: 10000,
        appointments_count: 1,
      },
      {
        employee_id: 3,
        employee_name: 'Andrés López',
        total_revenue: 18000,
        commission_percentage: 40,
        commission_amount: 7200,
        appointments_count: 1,
      },
      {
        employee_id: 4,
        employee_name: 'María García',
        total_revenue: 22000,
        commission_percentage: 35,
        commission_amount: 7700,
        appointments_count: 2,
      },
    ],
    is_closed: false,
    closed_at: null,
    closed_by_id: null,
  };
}

export function seedCashRegisterHistory(): CashRegisterClose[] {
  return [
    {
      id: 1,
      business_id: 1,
      date: daysAgo(1),
      total_revenue: 185000,
      total_commission: 42000,
      employee_payments: [
        { employee_id: 1, employee_name: 'Carlos Méndez', commission_amount: 0, paid: true },
        { employee_id: 2, employee_name: 'Juan Camilo Herrera', commission_amount: 22000, paid: true },
        { employee_id: 3, employee_name: 'Andrés López', commission_amount: 12000, paid: true },
        { employee_id: 4, employee_name: 'María García', commission_amount: 8000, paid: true },
      ],
      notes: null,
      closed_at: daysAgo(1) + 'T20:00:00Z',
      closed_by_id: 1,
    },
    {
      id: 2,
      business_id: 1,
      date: daysAgo(2),
      total_revenue: 210000,
      total_commission: 48000,
      employee_payments: [
        { employee_id: 1, employee_name: 'Carlos Méndez', commission_amount: 0, paid: true },
        { employee_id: 2, employee_name: 'Juan Camilo Herrera', commission_amount: 26000, paid: true },
        { employee_id: 3, employee_name: 'Andrés López', commission_amount: 14000, paid: true },
        { employee_id: 4, employee_name: 'María García', commission_amount: 8000, paid: true },
      ],
      notes: 'Día muy bueno, sábado lleno',
      closed_at: daysAgo(2) + 'T20:30:00Z',
      closed_by_id: 1,
    },
    {
      id: 3,
      business_id: 1,
      date: daysAgo(3),
      total_revenue: 120000,
      total_commission: 28000,
      employee_payments: [
        { employee_id: 1, employee_name: 'Carlos Méndez', commission_amount: 0, paid: true },
        { employee_id: 2, employee_name: 'Juan Camilo Herrera', commission_amount: 16000, paid: true },
        { employee_id: 3, employee_name: 'Andrés López', commission_amount: 8000, paid: false },
        { employee_id: 4, employee_name: 'María García', commission_amount: 4000, paid: true },
      ],
      notes: null,
      closed_at: daysAgo(3) + 'T19:30:00Z',
      closed_by_id: 1,
    },
  ];
}
