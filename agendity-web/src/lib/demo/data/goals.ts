// ============================================================
// Agendity — Demo seed: business goals
// ============================================================

export type GoalType = 'monthly_sales' | 'break_even' | 'daily_average';

export interface Goal {
  id: number;
  business_id: number;
  goal_type: GoalType;
  name: string;
  target_amount: number;
  current_amount: number;
  currency: string;
  period_start: string;
  period_end: string;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface GoalProgress {
  goal_id: number;
  goal_type: GoalType;
  name: string;
  target_amount: number;
  current_amount: number;
  percentage: number;
  remaining: number;
  on_track: boolean;
  projected_amount: number;
  days_remaining: number;
}

function monthStart(): string {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1).toISOString().split('T')[0];
}

function monthEnd(): string {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth() + 1, 0).toISOString().split('T')[0];
}

const now = new Date().toISOString();

export function seedGoals(): Goal[] {
  return [
    {
      id: 1,
      business_id: 1,
      goal_type: 'monthly_sales',
      name: 'Meta de ventas mensual',
      target_amount: 3000000,
      current_amount: 1850000,
      currency: 'COP',
      period_start: monthStart(),
      period_end: monthEnd(),
      active: true,
      created_at: now,
      updated_at: now,
    },
    {
      id: 2,
      business_id: 1,
      goal_type: 'break_even',
      name: 'Punto de equilibrio',
      target_amount: 1200000,
      current_amount: 1850000,
      currency: 'COP',
      period_start: monthStart(),
      period_end: monthEnd(),
      active: true,
      created_at: now,
      updated_at: now,
    },
    {
      id: 3,
      business_id: 1,
      goal_type: 'daily_average',
      name: 'Promedio diario',
      target_amount: 120000,
      current_amount: 95000,
      currency: 'COP',
      period_start: monthStart(),
      period_end: monthEnd(),
      active: true,
      created_at: now,
      updated_at: now,
    },
  ];
}

export function computeGoalProgress(goals: Goal[]): GoalProgress[] {
  const today = new Date();

  return goals.filter((g) => g.active).map((g) => {
    const start = new Date(g.period_start);
    const end = new Date(g.period_end);
    const totalDays = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)));
    const elapsedDays = Math.max(1, Math.ceil((today.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)));
    const daysRemaining = Math.max(0, Math.ceil((end.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)));

    const percentage = Math.min(100, Math.round((g.current_amount / g.target_amount) * 100));
    const dailyRate = g.current_amount / elapsedDays;
    const projected = Math.round(dailyRate * totalDays);

    return {
      goal_id: g.id,
      goal_type: g.goal_type,
      name: g.name,
      target_amount: g.target_amount,
      current_amount: g.current_amount,
      percentage,
      remaining: Math.max(0, g.target_amount - g.current_amount),
      on_track: projected >= g.target_amount,
      projected_amount: projected,
      days_remaining: daysRemaining,
    };
  });
}
