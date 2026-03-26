import { z } from 'zod';

export const businessProfileSchema = z.object({
  name: z.string().min(1, 'El nombre es requerido'),
  phone: z.string().min(1, 'El teléfono es requerido'),
  address: z.string().min(1, 'La dirección es requerida'),
  country: z.string().min(1, 'El país es requerido'),
  state: z.string().min(1, 'El departamento es requerido'),
  city: z.string().min(1, 'La ciudad es requerida'),
  description: z.string().optional(),
  instagram_url: z
    .string()
    .url('Ingresa una URL válida')
    .optional()
    .or(z.literal('')),
  facebook_url: z
    .string()
    .url('Ingresa una URL válida')
    .optional()
    .or(z.literal('')),
});

export const businessHoursSchema = z.object({
  hours: z.array(
    z.object({
      day_of_week: z.number().min(0).max(6),
      open_time: z.string(),
      close_time: z.string(),
      enabled: z.boolean(),
    }),
  ),
});

export const serviceSchema = z.object({
  name: z.string().min(1, 'El nombre del servicio es requerido'),
  price: z
    .number({ error: 'Ingresa un precio válido' })
    .positive('El precio debe ser mayor a 0'),
  duration_minutes: z
    .number({ error: 'Ingresa una duración válida' })
    .min(15, 'Mínimo 15 minutos')
    .max(480, 'Máximo 480 minutos'),
  description: z.string().optional(),
});

export const employeeSchema = z.object({
  name: z.string().min(1, 'El nombre es requerido'),
  phone: z.string().optional(),
  email: z
    .string()
    .email('Ingresa un correo válido')
    .optional()
    .or(z.literal('')),
});

export const paymentMethodsSchema = z.object({
  nequi_phone: z.string().optional(),
  daviplata_phone: z.string().optional(),
  bancolombia_account: z.string().optional(),
  breb_key: z.string().optional(),
});

export const cancellationPolicySchema = z.object({
  cancellation_policy_pct: z.enum(['0', '30', '50', '100'], {
    error: 'Selecciona un porcentaje de penalización',
  }),
  cancellation_deadline_hours: z
    .number({ error: 'Ingresa un número válido' })
    .min(1, 'Mínimo 1 hora')
    .max(72, 'Máximo 72 horas'),
});

export type BusinessProfileFormData = z.infer<typeof businessProfileSchema>;
export type BusinessHoursFormData = z.infer<typeof businessHoursSchema>;
export type ServiceFormData = z.infer<typeof serviceSchema>;
export type EmployeeFormData = z.infer<typeof employeeSchema>;
export type PaymentMethodsFormData = z.infer<typeof paymentMethodsSchema>;
export type CancellationPolicyFormData = z.infer<typeof cancellationPolicySchema>;
