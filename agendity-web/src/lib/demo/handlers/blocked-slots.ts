// ============================================================
// Agendity — Demo handlers: blocked slots
// ============================================================

import { route } from '../router';
import { getStore, updateStore, nextId } from '../store';
import type { BlockedSlot } from '@/lib/api/types';

// GET /api/v1/blocked_slots
route('get', '/api/v1/blocked_slots', ({ query }) => {
  const store = getStore();
  let filtered = [...store.blockedSlots];

  if (query.date) {
    filtered = filtered.filter((b) => b.date === query.date);
  }
  if (query.employee_id) {
    filtered = filtered.filter((b) => b.employee_id === Number(query.employee_id));
  }

  return { data: filtered };
});

// POST /api/v1/blocked_slots
route('post', '/api/v1/blocked_slots', ({ body }) => {
  const data = (body as any)?.blocked_slot ?? body;
  const now = new Date().toISOString();

  const slot: BlockedSlot = {
    id: nextId('blockedSlot'),
    business_id: 1,
    employee_id: data.employee_id ? Number(data.employee_id) : null,
    date: data.date,
    start_time: data.start_time,
    end_time: data.end_time,
    reason: data.reason ?? null,
    all_day: data.all_day ?? false,
    created_at: now,
    updated_at: now,
  };

  updateStore((s) => {
    s.blockedSlots.push(slot);
  });

  return { data: slot };
});

// DELETE /api/v1/blocked_slots/:id
route('delete', '/api/v1/blocked_slots/:id', ({ params }) => {
  const id = Number(params.id);
  updateStore((s) => {
    s.blockedSlots = s.blockedSlots.filter((b) => b.id !== id);
  });
  return { data: null };
});
