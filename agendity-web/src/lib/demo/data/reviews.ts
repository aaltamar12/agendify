// ============================================================
// Agendity — Demo seed: reviews
// ============================================================

import type { Review, Customer, Employee } from '@/lib/api/types';

const now = '2026-03-15T10:00:00Z';

export function seedReviews(customers: Customer[], employees: Employee[]): Review[] {
  const reviewData: { customerIdx: number; employeeIdx: number; rating: number; comment: string | null }[] = [
    { customerIdx: 0, employeeIdx: 0, rating: 5, comment: 'Excelente corte, Carlos es el mejor. Siempre salgo feliz.' },
    { customerIdx: 2, employeeIdx: 1, rating: 5, comment: 'El fade quedó impecable. Juan Camilo tiene mucho talento.' },
    { customerIdx: 4, employeeIdx: 0, rating: 4, comment: 'Muy buen servicio, aunque tuve que esperar un poco.' },
    { customerIdx: 6, employeeIdx: 2, rating: 5, comment: 'Andrés hizo un trabajo increíble con el tinte. Quedó natural.' },
    { customerIdx: 7, employeeIdx: 3, rating: 5, comment: 'María me dejó las cejas perfectas. Super recomendada.' },
    { customerIdx: 9, employeeIdx: 0, rating: 4, comment: 'Buen corte como siempre. El lugar es muy limpio.' },
    { customerIdx: 10, employeeIdx: 2, rating: 4, comment: 'Buen tratamiento capilar, se nota la diferencia.' },
    { customerIdx: 12, employeeIdx: 1, rating: 5, comment: 'Mi hijo quedó encantado con su corte. Volveremos!' },
    { customerIdx: 14, employeeIdx: 0, rating: 5, comment: 'La mejor barbería de Barranquilla, sin duda.' },
    { customerIdx: 3, employeeIdx: 1, rating: 4, comment: null },
  ];

  return reviewData.map((r, i) => ({
    id: i + 1,
    appointment_id: i + 1,
    customer_id: customers[r.customerIdx]?.id ?? 1,
    business_id: 1,
    employee_id: employees[r.employeeIdx]?.id ?? 1,
    rating: r.rating,
    comment: r.comment,
    created_at: now,
    updated_at: now,
    customer: customers[r.customerIdx],
  }));
}
