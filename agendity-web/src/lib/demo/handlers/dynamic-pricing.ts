// ============================================================
// Agendity — Demo handlers: dynamic pricing
// ============================================================

import { route } from '../router';
import { getStore, updateStore } from '../store';

// GET /api/v1/dynamic_pricing
route('get', '/api/v1/dynamic_pricing', () => {
  const store = getStore();
  return { data: store.dynamicPricings };
});

// POST /api/v1/dynamic_pricing
route('post', '/api/v1/dynamic_pricing', ({ body }) => {
  const data = (body as any)?.dynamic_pricing ?? body;
  const now = new Date().toISOString();

  const pricing = {
    id: getStore().dynamicPricings.length + 10,
    business_id: 1,
    name: data.name ?? 'Nueva regla',
    discount_percentage: data.discount_percentage ?? 0,
    days_of_week: data.days_of_week ?? [],
    start_time: data.start_time ?? null,
    end_time: data.end_time ?? null,
    start_date: data.start_date ?? new Date().toISOString().split('T')[0],
    end_date: data.end_date ?? '',
    active: data.active ?? true,
    source: 'manual' as const,
    ai_accepted: null,
    ai_reason: null,
    created_at: now,
    updated_at: now,
  };

  updateStore((s) => {
    s.dynamicPricings.push(pricing);
  });

  return { data: pricing };
});

// PATCH /api/v1/dynamic_pricing/:id/accept
route('patch', '/api/v1/dynamic_pricing/:id/accept', ({ params }) => {
  const id = Number(params.id);
  const now = new Date().toISOString();

  updateStore((s) => {
    const pricing = s.dynamicPricings.find((p) => p.id === id);
    if (pricing) {
      pricing.ai_accepted = true;
      pricing.active = true;
      pricing.updated_at = now;
    }
  });

  const pricing = getStore().dynamicPricings.find((p) => p.id === id);
  return { data: pricing };
});

// PATCH /api/v1/dynamic_pricing/:id/reject
route('patch', '/api/v1/dynamic_pricing/:id/reject', ({ params }) => {
  const id = Number(params.id);
  const now = new Date().toISOString();

  updateStore((s) => {
    const pricing = s.dynamicPricings.find((p) => p.id === id);
    if (pricing) {
      pricing.ai_accepted = false;
      pricing.active = false;
      pricing.updated_at = now;
    }
  });

  const pricing = getStore().dynamicPricings.find((p) => p.id === id);
  return { data: pricing };
});

// DELETE /api/v1/dynamic_pricing/:id
route('delete', '/api/v1/dynamic_pricing/:id', ({ params }) => {
  const id = Number(params.id);

  updateStore((s) => {
    s.dynamicPricings = s.dynamicPricings.filter((p) => p.id !== id);
  });

  return { data: null };
});
