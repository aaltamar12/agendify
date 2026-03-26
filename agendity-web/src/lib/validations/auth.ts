import { z } from 'zod';

export const loginSchema = z.object({
  email: z
    .string()
    .min(1, 'El correo es requerido')
    .email('Ingresa un correo válido'),
  password: z
    .string()
    .min(6, 'La contraseña debe tener al menos 6 caracteres'),
});

export const registerSchema = z
  .object({
    name: z.string().min(1, 'El nombre es requerido'),
    email: z
      .string()
      .min(1, 'El correo es requerido')
      .email('Ingresa un correo válido'),
    password: z
      .string()
      .min(6, 'La contraseña debe tener al menos 6 caracteres'),
    passwordConfirmation: z
      .string()
      .min(1, 'Confirma tu contraseña'),
    businessName: z.string().min(1, 'El nombre del negocio es requerido'),
    businessType: z.enum(['barbershop', 'salon', 'spa', 'nails', 'estetica', 'consultorio', 'other'], {
      error: 'Selecciona el tipo de negocio',
    }),
    termsAccepted: z.literal(true, {
      error: 'Debes aceptar los términos y condiciones',
    }),
    referralCode: z.string().optional(),
  })
  .refine((data) => data.password === data.passwordConfirmation, {
    message: 'Las contraseñas no coinciden',
    path: ['passwordConfirmation'],
  });

export const forgotPasswordSchema = z.object({
  email: z
    .string()
    .min(1, 'El correo es requerido')
    .email('Ingresa un correo válido'),
});

export const resetPasswordSchema = z
  .object({
    password: z
      .string()
      .min(6, 'La contraseña debe tener al menos 6 caracteres'),
    passwordConfirmation: z
      .string()
      .min(1, 'Confirma tu contraseña'),
  })
  .refine((data) => data.password === data.passwordConfirmation, {
    message: 'Las contraseñas no coinciden',
    path: ['passwordConfirmation'],
  });

export type LoginFormData = z.infer<typeof loginSchema>;
export type RegisterFormData = z.infer<typeof registerSchema>;
export type ForgotPasswordFormData = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordFormData = z.infer<typeof resetPasswordSchema>;
