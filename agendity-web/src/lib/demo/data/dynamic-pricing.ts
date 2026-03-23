// ============================================================
// Agendity — Demo seed: dynamic pricing rules
// ============================================================

export interface DynamicPricing {
  id: number;
  business_id: number;
  name: string;
  discount_percentage: number;
  days_of_week: number[];
  start_time: string | null;
  end_time: string | null;
  start_date: string;
  end_date: string;
  active: boolean;
  source: 'manual' | 'ai_suggestion';
  ai_accepted: boolean | null;
  ai_reason: string | null;
  created_at: string;
  updated_at: string;
}

function daysFromNow(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d.toISOString().split('T')[0];
}

function daysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().split('T')[0];
}

const now = new Date().toISOString();

export function seedDynamicPricings(): DynamicPricing[] {
  return [
    {
      id: 1,
      business_id: 1,
      name: 'Descuento entre semana',
      discount_percentage: -15,
      days_of_week: [1, 2, 3, 4], // Mon-Thu
      start_time: null,
      end_time: null,
      start_date: daysAgo(30),
      end_date: daysFromNow(60),
      active: true,
      source: 'manual',
      ai_accepted: null,
      ai_reason: null,
      created_at: now,
      updated_at: now,
    },
    {
      id: 2,
      business_id: 1,
      name: 'Recargo fin de semana',
      discount_percentage: 20,
      days_of_week: [5, 6], // Fri-Sat
      start_time: null,
      end_time: null,
      start_date: daysAgo(30),
      end_date: daysFromNow(60),
      active: true,
      source: 'manual',
      ai_accepted: null,
      ai_reason: null,
      created_at: now,
      updated_at: now,
    },
    {
      id: 3,
      business_id: 1,
      name: 'Happy Hour martes mañana',
      discount_percentage: -25,
      days_of_week: [2], // Tuesday
      start_time: '08:00',
      end_time: '11:00',
      start_date: daysFromNow(1),
      end_date: daysFromNow(90),
      active: false,
      source: 'ai_suggestion',
      ai_accepted: null,
      ai_reason:
        'Los martes por la mañana tienen un 40% menos de ocupación que el promedio. Un descuento del 25% podría aumentar las reservas en ese horario en un 60% según el historial.',
      created_at: now,
      updated_at: now,
    },
  ];
}
