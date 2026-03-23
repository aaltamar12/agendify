// ============================================================
// Agendity — Demo handlers: business goals
// ============================================================

import { route } from '../router';
import { getStore, updateStore } from '../store';
import { computeGoalProgress } from '../data/goals';

// GET /api/v1/goals
route('get', '/api/v1/goals', () => {
  const store = getStore();
  return { data: store.goals };
});

// POST /api/v1/goals
route('post', '/api/v1/goals', ({ body }) => {
  const data = (body as any)?.goal ?? body;
  const now = new Date().toISOString();

  const goal = {
    id: getStore().goals.length + 10,
    business_id: 1,
    goal_type: data.goal_type ?? 'monthly_sales',
    name: data.name ?? 'Nueva meta',
    target_amount: data.target_amount ?? 0,
    current_amount: 0,
    currency: 'COP',
    period_start: data.period_start ?? new Date().toISOString().split('T')[0],
    period_end: data.period_end ?? '',
    active: true,
    created_at: now,
    updated_at: now,
  };

  updateStore((s) => {
    s.goals.push(goal);
  });

  return { data: goal };
});

// DELETE /api/v1/goals/:id
route('delete', '/api/v1/goals/:id', ({ params }) => {
  const id = Number(params.id);

  updateStore((s) => {
    s.goals = s.goals.filter((g) => g.id !== id);
  });

  return { data: null };
});

// GET /api/v1/goals/progress
route('get', '/api/v1/goals/progress', () => {
  const store = getStore();
  const progress = computeGoalProgress(store.goals);
  return { data: progress };
});
