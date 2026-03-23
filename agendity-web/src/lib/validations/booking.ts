import { z } from 'zod';

export const customerInfoSchema = z.object({
  name: z
    .string()
    .min(1, 'El nombre es obligatorio')
    .min(2, 'El nombre debe tener al menos 2 caracteres'),
  email: z
    .string()
    .min(1, 'El correo es obligatorio')
    .email('Ingresa un correo válido'),
  phone: z
    .string()
    .min(1, 'El teléfono es obligatorio')
    .regex(/^\d{7,}$/, 'Ingresa un teléfono válido (mínimo 7 dígitos)'),
  birth_date: z
    .string()
    .optional()
    .refine(
      (val) => !val || /^\d{4}-\d{2}-\d{2}$/.test(val),
      'Fecha no válida',
    ),
});

export type CustomerInfoFormData = z.infer<typeof customerInfoSchema>;
