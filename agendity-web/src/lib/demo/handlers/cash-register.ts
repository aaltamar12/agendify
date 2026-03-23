// ============================================================
// Agendity — Demo handlers: cash register
// ============================================================

import { route } from '../router';
import { getStore, updateStore } from '../store';

// GET /api/v1/cash_register/today
route('get', '/api/v1/cash_register/today', () => {
  const store = getStore();
  return { data: store.cashRegisterToday };
});

// POST /api/v1/cash_register/close
route('post', '/api/v1/cash_register/close', ({ body }) => {
  const data = (body as any) ?? {};
  const now = new Date().toISOString();
  const today = new Date().toISOString().split('T')[0];
  const store = getStore();
  const summary = store.cashRegisterToday;

  const close = {
    id: store.cashRegisterHistory.length + 10,
    business_id: 1,
    date: today,
    total_revenue: summary.total_revenue,
    total_commission: summary.employee_breakdown.reduce(
      (sum, e) => sum + e.commission_amount,
      0,
    ),
    employee_payments: summary.employee_breakdown.map((e) => ({
      employee_id: e.employee_id,
      employee_name: e.employee_name,
      commission_amount: e.commission_amount,
      paid: true,
    })),
    notes: data.notes ?? null,
    closed_at: now,
    closed_by_id: 1,
  };

  updateStore((s) => {
    s.cashRegisterHistory.unshift(close);
    s.cashRegisterToday.is_closed = true;
    s.cashRegisterToday.closed_at = now;
    s.cashRegisterToday.closed_by_id = 1;

    // Reset employee pending balances
    for (const ep of close.employee_payments) {
      const emp = s.employees.find((e) => e.id === ep.employee_id);
      if (emp && (emp as any).pending_balance !== undefined) {
        (emp as any).pending_balance = 0;
      }
    }
  });

  return { data: close };
});

// GET /api/v1/cash_register/history
route('get', '/api/v1/cash_register/history', ({ query }) => {
  const store = getStore();
  const page = Number(query.page) || 1;
  const perPage = Number(query.per_page) || 10;

  const sorted = [...store.cashRegisterHistory].sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
  );

  const totalCount = sorted.length;
  const totalPages = Math.ceil(totalCount / perPage);
  const start = (page - 1) * perPage;
  const data = sorted.slice(start, start + perPage);

  return {
    data,
    meta: {
      current_page: page,
      total_pages: totalPages,
      total_count: totalCount,
      per_page: perPage,
    },
  };
});
