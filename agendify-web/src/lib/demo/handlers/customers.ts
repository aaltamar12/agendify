// ============================================================
// Agendify — Demo handlers: customers
// ============================================================

import { route } from '../router';
import { getStore } from '../store';

// GET /api/v1/customers (paginated + search)
route('get', '/api/v1/customers', ({ query }) => {
  const store = getStore();
  const page = Number(query.page) || 1;
  const perPage = Number(query.per_page) || 20;
  const search = (query.q ?? '').toLowerCase();

  let filtered = store.customers;

  if (search) {
    filtered = filtered.filter(
      (c) =>
        c.name.toLowerCase().includes(search) ||
        c.phone.includes(search) ||
        (c.email?.toLowerCase().includes(search) ?? false),
    );
  }

  const totalCount = filtered.length;
  const totalPages = Math.ceil(totalCount / perPage);
  const start = (page - 1) * perPage;
  const data = filtered.slice(start, start + perPage);

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

// GET /api/v1/customers/:id
route('get', '/api/v1/customers/:id', ({ params }) => {
  const id = Number(params.id);
  const store = getStore();
  const customer = store.customers.find((c) => c.id === id);

  if (!customer) {
    throw { status: 404, message: 'Cliente no encontrado' };
  }

  // Include appointment history
  const appointments = store.appointments.filter((a) => a.customer_id === id);

  return {
    data: {
      ...customer,
      appointments: appointments.map((a) => ({
        ...a,
        service: store.services.find((s) => s.id === a.service_id),
        employee: store.employees.find((e) => e.id === a.employee_id),
      })),
    },
  };
});
