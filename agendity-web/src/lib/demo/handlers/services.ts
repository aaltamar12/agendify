// ============================================================
// Agendity — Demo handlers: services CRUD
// ============================================================

import { route } from '../router';
import { getStore, updateStore, nextId } from '../store';
import type { Service } from '@/lib/api/types';

// GET /api/v1/services
route('get', '/api/v1/services', () => {
  const store = getStore();
  return { data: store.services };
});

// POST /api/v1/services
route('post', '/api/v1/services', ({ body }) => {
  const data = (body as any)?.service ?? body;
  const now = new Date().toISOString();
  const service: Service = {
    id: nextId('service'),
    business_id: 1,
    name: data.name ?? 'Nuevo Servicio',
    description: data.description ?? null,
    duration_minutes: data.duration_minutes ?? 30,
    price: data.price ?? 0,
    active: data.active ?? true,
    category: data.category ?? null,
    image_url: null,
    created_at: now,
    updated_at: now,
  };

  updateStore((s) => {
    s.services.push(service);
  });

  return { data: service };
});

// PUT /api/v1/services/:id
route('put', '/api/v1/services/:id', ({ params, body }) => {
  const id = Number(params.id);
  const data = (body as any)?.service ?? body;

  updateStore((s) => {
    const svc = s.services.find((x) => x.id === id);
    if (svc) {
      Object.assign(svc, data, { updated_at: new Date().toISOString() });
    }
  });

  const store = getStore();
  const updated = store.services.find((x) => x.id === id);
  return { data: updated };
});

// DELETE /api/v1/services/:id
route('delete', '/api/v1/services/:id', ({ params }) => {
  const id = Number(params.id);
  updateStore((s) => {
    s.services = s.services.filter((x) => x.id !== id);
  });
  return { data: null };
});
