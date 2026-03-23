// ============================================================
// Agendity — Demo seed: employees
// ============================================================

import type { Employee } from '@/lib/api/types';

const now = '2026-03-15T10:00:00Z';

export function seedEmployees(): Employee[] {
  return [
    {
      id: 1,
      business_id: 1,
      user_id: null,
      name: 'Carlos Méndez',
      email: 'carlos@barberiaelite.co',
      phone: '+573012345678',
      avatar_url: null,
      bio: 'Fundador y barbero principal. 8 años de experiencia en cortes modernos.',
      active: true,
      commission_percentage: 0,
      pending_balance: 0,
      score: 95,
      rating_avg: 4.8,
      has_account: true,
      created_at: now,
      updated_at: now,
    },
    {
      id: 2,
      business_id: 1,
      user_id: null,
      name: 'Juan Camilo Herrera',
      email: 'juanc@barberiaelite.co',
      phone: '+573023456789',
      avatar_url: null,
      bio: 'Especialista en fades y diseños. Barbero certificado.',
      active: true,
      commission_percentage: 40,
      pending_balance: 85000,
      score: 88,
      rating_avg: 4.6,
      has_account: true,
      created_at: now,
      updated_at: now,
    },
    {
      id: 3,
      business_id: 1,
      user_id: null,
      name: 'Andrés López',
      email: 'andres@barberiaelite.co',
      phone: '+573034567890',
      avatar_url: null,
      bio: 'Experto en colorimetría y tratamientos capilares.',
      active: true,
      commission_percentage: 40,
      pending_balance: 62000,
      score: 82,
      rating_avg: 4.5,
      has_account: false,
      created_at: now,
      updated_at: now,
    },
    {
      id: 4,
      business_id: 1,
      user_id: null,
      name: 'María García',
      email: 'maria@barberiaelite.co',
      phone: '+573045678901',
      avatar_url: null,
      bio: 'Estilista integral. Especializada en cejas y diseño facial.',
      active: true,
      commission_percentage: 35,
      pending_balance: 45000,
      score: 90,
      rating_avg: 4.9,
      has_account: true,
      created_at: now,
      updated_at: now,
    },
  ];
}
