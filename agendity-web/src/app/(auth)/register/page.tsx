'use client';

import { useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input, Select, Card } from '@/components/ui';
import { registerSchema, type RegisterFormData } from '@/lib/validations/auth';
import { useRegister } from '@/lib/hooks/use-auth';

const businessTypeOptions = [
  { value: 'barberia', label: 'Barbería' },
  { value: 'salon', label: 'Salón de belleza' },
  { value: 'spa', label: 'Spa' },
  { value: 'nails', label: 'Estudio de uñas' },
  { value: 'estetica', label: 'Centro de estética' },
  { value: 'consultorio', label: 'Consultorio' },
  { value: 'other', label: 'Otro tipo de negocio' },
];

export default function RegisterPage() {
  const searchParams = useSearchParams();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      businessType: undefined,
    },
  });

  // Capture referral code from URL and persist in localStorage
  useEffect(() => {
    const ref = searchParams.get('ref');
    if (ref) {
      localStorage.setItem('agendity_ref_code', ref);
    }
  }, [searchParams]);

  const registerMutation = useRegister();

  const onSubmit = (data: RegisterFormData) => {
    const referralCode = localStorage.getItem('agendity_ref_code') || undefined;
    registerMutation.mutate({ ...data, referralCode });
  };

  return (
    <Card>
      <h2 className="mb-6 text-center text-xl font-semibold text-gray-900">
        Crear cuenta
      </h2>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Input
          label="Nombre completo"
          placeholder="Tu nombre"
          error={errors.name?.message}
          {...register('name')}
        />

        <Input
          label="Correo electrónico"
          type="email"
          placeholder="tu@correo.com"
          error={errors.email?.message}
          {...register('email')}
        />

        <Input
          label="Contraseña"
          type="password"
          placeholder="Mínimo 6 caracteres"
          error={errors.password?.message}
          {...register('password')}
        />

        <Input
          label="Confirmar contraseña"
          type="password"
          placeholder="Repite tu contraseña"
          error={errors.passwordConfirmation?.message}
          {...register('passwordConfirmation')}
        />

        <Input
          label="Nombre del negocio"
          placeholder="Ej: Barbería Don Juan"
          error={errors.businessName?.message}
          {...register('businessName')}
        />

        <Select
          label="Tipo de negocio"
          options={businessTypeOptions}
          placeholder="Selecciona el tipo"
          error={errors.businessType?.message}
          {...register('businessType')}
        />

        {registerMutation.isError && (
          <p className="text-sm text-red-600">
            {(registerMutation.error as Error)?.message ||
              'Hubo un error al crear la cuenta. Intenta de nuevo.'}
          </p>
        )}

        <Button
          type="submit"
          fullWidth
          loading={registerMutation.isPending}
        >
          Crear cuenta
        </Button>
      </form>

      <p className="mt-4 text-center text-sm text-gray-600">
        ¿Ya tienes cuenta?{' '}
        <Link
          href="/login"
          className="font-medium text-violet-600 hover:text-violet-700"
        >
          Inicia sesión
        </Link>
      </p>
    </Card>
  );
}
