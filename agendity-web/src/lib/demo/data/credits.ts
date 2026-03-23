// ============================================================
// Agendity — Demo seed: credits (cashback, refunds, etc.)
// ============================================================

export interface CreditAccount {
  id: number;
  customer_id: number;
  business_id: number;
  balance: number;
  created_at: string;
  updated_at: string;
}

export type CreditTransactionType = 'cashback' | 'refund' | 'redemption' | 'manual_adjustment';

export interface CreditTransaction {
  id: number;
  credit_account_id: number;
  customer_id: number;
  business_id: number;
  amount: number;
  balance_after: number;
  transaction_type: CreditTransactionType;
  description: string;
  appointment_id: number | null;
  created_by_id: number | null;
  created_at: string;
}

const now = '2026-03-15T10:00:00Z';

export function seedCreditAccounts(): CreditAccount[] {
  return [
    { id: 1, customer_id: 1, business_id: 1, balance: 3750, created_at: now, updated_at: now },
    { id: 2, customer_id: 3, business_id: 1, balance: 6250, created_at: now, updated_at: now },
    { id: 3, customer_id: 5, business_id: 1, balance: 12500, created_at: now, updated_at: now },
    { id: 4, customer_id: 7, business_id: 1, balance: 1000, created_at: now, updated_at: now },
    { id: 5, customer_id: 10, business_id: 1, balance: 4500, created_at: now, updated_at: now },
    { id: 6, customer_id: 14, business_id: 1, balance: 2000, created_at: now, updated_at: now },
  ];
}

export function seedCreditTransactions(): CreditTransaction[] {
  return [
    // Customer 1 — Santiago Ospina
    {
      id: 1,
      credit_account_id: 1,
      customer_id: 1,
      business_id: 1,
      amount: 750,
      balance_after: 750,
      transaction_type: 'cashback',
      description: 'Cashback 5% — Corte Clásico',
      appointment_id: 1,
      created_by_id: null,
      created_at: '2026-02-20T10:00:00Z',
    },
    {
      id: 2,
      credit_account_id: 1,
      customer_id: 1,
      business_id: 1,
      amount: 1250,
      balance_after: 2000,
      transaction_type: 'cashback',
      description: 'Cashback 5% — Corte + Barba',
      appointment_id: 6,
      created_by_id: null,
      created_at: '2026-03-01T09:30:00Z',
    },
    {
      id: 3,
      credit_account_id: 1,
      customer_id: 1,
      business_id: 1,
      amount: 1750,
      balance_after: 3750,
      transaction_type: 'refund',
      description: 'Reembolso por cancelación — crédito a favor',
      appointment_id: null,
      created_by_id: 1,
      created_at: '2026-03-10T14:00:00Z',
    },
    // Customer 3 — Mateo Jiménez
    {
      id: 4,
      credit_account_id: 2,
      customer_id: 3,
      business_id: 1,
      amount: 1000,
      balance_after: 1000,
      transaction_type: 'cashback',
      description: 'Cashback 5% — Fade Degradado',
      appointment_id: 3,
      created_by_id: null,
      created_at: '2026-02-22T11:00:00Z',
    },
    {
      id: 5,
      credit_account_id: 2,
      customer_id: 3,
      business_id: 1,
      amount: -750,
      balance_after: 250,
      transaction_type: 'redemption',
      description: 'Redención en cita #10',
      appointment_id: 10,
      created_by_id: null,
      created_at: '2026-03-13T14:00:00Z',
    },
    {
      id: 6,
      credit_account_id: 2,
      customer_id: 3,
      business_id: 1,
      amount: 5000,
      balance_after: 5250,
      transaction_type: 'manual_adjustment',
      description: 'Ajuste manual — compensación por inconveniente',
      appointment_id: null,
      created_by_id: 1,
      created_at: '2026-03-14T16:00:00Z',
    },
    {
      id: 7,
      credit_account_id: 2,
      customer_id: 3,
      business_id: 1,
      amount: 1000,
      balance_after: 6250,
      transaction_type: 'cashback',
      description: 'Cashback 5% — Fade Degradado',
      appointment_id: 10,
      created_by_id: null,
      created_at: '2026-03-15T14:00:00Z',
    },
    // Customer 5 — Daniel Acosta
    {
      id: 8,
      credit_account_id: 3,
      customer_id: 5,
      business_id: 1,
      amount: 12500,
      balance_after: 12500,
      transaction_type: 'refund',
      description: 'Reembolso completo — cancelación dentro del plazo',
      appointment_id: 25,
      created_by_id: null,
      created_at: '2026-03-12T10:00:00Z',
    },
  ];
}
