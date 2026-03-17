// ============================================================
// Agendity — Demo seed: customers
// ============================================================

import type { Customer } from '@/lib/api/types';

const now = '2026-03-15T10:00:00Z';

export function seedCustomers(): Customer[] {
  return [
    { id: 1, business_id: 1, name: 'Santiago Ospina', phone: '+573101234567', email: 'santiago.ospina@gmail.com', notes: 'Prefiere corte bajo', total_visits: 12, last_visit_at: '2026-03-14T15:00:00Z', created_at: now, updated_at: now },
    { id: 2, business_id: 1, name: 'Valentina Restrepo', phone: '+573112345678', email: 'vale.restrepo@gmail.com', notes: null, total_visits: 8, last_visit_at: '2026-03-13T10:00:00Z', created_at: now, updated_at: now },
    { id: 3, business_id: 1, name: 'Mateo Jiménez', phone: '+573123456789', email: 'mateo.jimenez@hotmail.com', notes: 'Alergia al gel', total_visits: 15, last_visit_at: '2026-03-15T11:00:00Z', created_at: now, updated_at: now },
    { id: 4, business_id: 1, name: 'Isabella Moreno', phone: '+573134567890', email: 'isabella.m@gmail.com', notes: null, total_visits: 5, last_visit_at: '2026-03-10T14:00:00Z', created_at: now, updated_at: now },
    { id: 5, business_id: 1, name: 'Daniel Acosta', phone: '+573145678901', email: 'daniel.acosta@outlook.com', notes: 'Solo con Carlos', total_visits: 20, last_visit_at: '2026-03-16T09:00:00Z', created_at: now, updated_at: now },
    { id: 6, business_id: 1, name: 'Camila Duarte', phone: '+573156789012', email: 'cami.duarte@gmail.com', notes: null, total_visits: 3, last_visit_at: '2026-03-08T16:00:00Z', created_at: now, updated_at: now },
    { id: 7, business_id: 1, name: 'Sebastián Rojas', phone: '+573167890123', email: 'seba.rojas@gmail.com', notes: null, total_visits: 10, last_visit_at: '2026-03-14T11:00:00Z', created_at: now, updated_at: now },
    { id: 8, business_id: 1, name: 'Luciana Vargas', phone: '+573178901234', email: 'lu.vargas@gmail.com', notes: 'Cejas delgadas', total_visits: 6, last_visit_at: '2026-03-12T10:00:00Z', created_at: now, updated_at: now },
    { id: 9, business_id: 1, name: 'Nicolás Bermúdez', phone: '+573189012345', email: 'nico.bermudez@hotmail.com', notes: null, total_visits: 4, last_visit_at: '2026-03-09T15:00:00Z', created_at: now, updated_at: now },
    { id: 10, business_id: 1, name: 'Mariana Torres', phone: '+573190123456', email: 'mariana.t@gmail.com', notes: null, total_visits: 7, last_visit_at: '2026-03-13T17:00:00Z', created_at: now, updated_at: now },
    { id: 11, business_id: 1, name: 'Alejandro Peña', phone: '+573201234567', email: 'ale.pena@outlook.com', notes: 'Tinte rubio', total_visits: 9, last_visit_at: '2026-03-11T13:00:00Z', created_at: now, updated_at: now },
    { id: 12, business_id: 1, name: 'Sofía Cardona', phone: '+573212345678', email: 'sofi.cardona@gmail.com', notes: null, total_visits: 2, last_visit_at: '2026-03-05T10:00:00Z', created_at: now, updated_at: now },
    { id: 13, business_id: 1, name: 'Tomás Salazar', phone: '+573223456789', email: 'tomas.salazar@gmail.com', notes: null, total_visits: 11, last_visit_at: '2026-03-15T16:00:00Z', created_at: now, updated_at: now },
    { id: 14, business_id: 1, name: 'Paula Andrea Ríos', phone: '+573234567890', email: 'paula.rios@hotmail.com', notes: 'Prefiere tarde', total_visits: 6, last_visit_at: '2026-03-12T17:00:00Z', created_at: now, updated_at: now },
    { id: 15, business_id: 1, name: 'Felipe Castro', phone: '+573245678901', email: 'felipe.castro@gmail.com', notes: null, total_visits: 14, last_visit_at: '2026-03-16T11:00:00Z', created_at: now, updated_at: now },
  ];
}
