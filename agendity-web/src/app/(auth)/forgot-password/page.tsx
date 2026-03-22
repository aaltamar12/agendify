'use client';

import Link from 'next/link';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input, Card } from '@/components/ui';
import { forgotPasswordSchema, type ForgotPasswordFormData } from '@/lib/validations/auth';
import { useForgotPassword } from '@/lib/hooks/use-auth';

export default function ForgotPasswordPage() {
  const [submitted, setSubmitted] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ForgotPasswordFormData>({
    resolver: zodResolver(forgotPasswordSchema),
  });

  const mutation = useForgotPassword();

  const onSubmit = (data: ForgotPasswordFormData) => {
    mutation.mutate(data, {
      onSuccess: () => setSubmitted(true),
    });
  };

  if (submitted) {
    return (
      <Card>
        <div className="text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
            <svg className="h-6 w-6 text-green-600" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
            </svg>
          </div>
          <h2 className="mb-2 text-xl font-semibold text-gray-900">
            Revisa tu correo
          </h2>
          <p className="mb-6 text-sm text-gray-600">
            Si el correo está registrado, recibirás instrucciones para restablecer tu contraseña.
          </p>
          <Link
            href="/login"
            className="text-sm font-medium text-violet-600 hover:text-violet-700"
          >
            Volver a iniciar sesión
          </Link>
        </div>
      </Card>
    );
  }

  return (
    <Card>
      <h2 className="mb-2 text-center text-xl font-semibold text-gray-900">
        Recuperar contraseña
      </h2>
      <p className="mb-6 text-center text-sm text-gray-600">
        Ingresa tu correo y te enviaremos instrucciones para restablecer tu contraseña.
      </p>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Input
          label="Correo electrónico"
          type="email"
          placeholder="tu@correo.com"
          error={errors.email?.message}
          {...register('email')}
        />

        {mutation.isError && (
          <p className="text-sm text-red-600">
            Ocurrió un error. Intenta de nuevo.
          </p>
        )}

        <Button
          type="submit"
          fullWidth
          loading={mutation.isPending}
        >
          Enviar instrucciones
        </Button>
      </form>

      <p className="mt-4 text-center text-sm text-gray-600">
        <Link
          href="/login"
          className="font-medium text-violet-600 hover:text-violet-700"
        >
          Volver a iniciar sesión
        </Link>
      </p>
    </Card>
  );
}
