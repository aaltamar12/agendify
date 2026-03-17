// ============================================================
// Agendify — Demo handlers: employees CRUD
// ============================================================

import { route } from '../router';
import { getStore, updateStore, nextId } from '../store';
import type { Employee } from '@/lib/api/types';

// GET /api/v1/employees
route('get', '/api/v1/employees', () => {
  const store = getStore();
  return { data: store.employees };
});

// POST /api/v1/employees
route('post', '/api/v1/employees', ({ body }) => {
  const data = (body as any)?.employee ?? body;
  const now = new Date().toISOString();
  const employee: Employee = {
    id: nextId('employee'),
    business_id: 1,
    user_id: null,
    name: data.name ?? 'Nuevo Empleado',
    email: data.email ?? null,
    phone: data.phone ?? null,
    avatar_url: null,
    bio: data.bio ?? null,
    active: data.active ?? true,
    commission_percentage: data.commission_percentage ?? null,
    created_at: now,
    updated_at: now,
  };

  updateStore((s) => {
    s.employees.push(employee);
  });

  return { data: employee };
});

// PUT /api/v1/employees/:id
route('put', '/api/v1/employees/:id', ({ params, body }) => {
  const id = Number(params.id);
  const data = (body as any)?.employee ?? body;

  updateStore((s) => {
    const emp = s.employees.find((x) => x.id === id);
    if (emp) {
      Object.assign(emp, data, { updated_at: new Date().toISOString() });
    }
  });

  const store = getStore();
  const updated = store.employees.find((x) => x.id === id);
  return { data: updated };
});

// DELETE /api/v1/employees/:id
route('delete', '/api/v1/employees/:id', ({ params }) => {
  const id = Number(params.id);
  updateStore((s) => {
    s.employees = s.employees.filter((x) => x.id !== id);
  });
  return { data: null };
});
