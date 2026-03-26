import { z } from 'zod';

// --- Create appointment schema ---

export const createAppointmentSchema = z.object({
  service_id: z
    .number({ error: 'Selecciona un servicio' })
    .min(1, 'Selecciona un servicio'),
  employee_id: z
    .number({ error: 'Selecciona un empleado' })
    .min(1, 'Selecciona un empleado'),
  customer_name: z
    .string()
    .min(1, 'El nombre del cliente es requerido'),
  customer_email: z
    .string()
    .email('Ingresa un correo válido')
    .optional()
    .or(z.literal('')),
  customer_phone: z
    .string()
    .min(1, 'El teléfono es requerido')
    .regex(/^3\d{9}$/, 'Ingresa un teléfono válido (10 dígitos, ej: 3001234567)'),
  appointment_date: z
    .string()
    .min(1, 'La fecha es requerida'),
  start_time: z
    .string()
    .min(1, 'La hora es requerida'),
  notes: z.string().optional(),
});

export type CreateAppointmentFormData = z.infer<typeof createAppointmentSchema>;

// --- Block slot schema ---

export const blockSlotSchema = z.object({
  employee_id: z
    .number()
    .optional(),
  date: z
    .string()
    .min(1, 'La fecha es requerida'),
  start_time: z
    .string()
    .min(1, 'La hora de inicio es requerida'),
  end_time: z
    .string()
    .min(1, 'La hora de fin es requerida'),
  reason: z.string().optional(),
});

export type BlockSlotFormData = z.infer<typeof blockSlotSchema>;
