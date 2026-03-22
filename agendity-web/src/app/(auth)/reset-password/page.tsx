'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input, Card } from '@/components/ui';
import { resetPasswordSchema, type ResetPasswordFormData } from '@/lib/validations/auth';
import { useResetPassword } from '@/lib/hooks/use-auth';

export default function ResetPasswordPage() {
  const searchParams = useSearchParams();
  const token = searchParams.get('token');

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ResetPasswordFormData>({
    resolver: zodResolver(resetPasswordSchema),
  });

  const mutation = useResetPassword();

  const onSubmit = (data: ResetPasswordFormData) => {
    if (!token) return;
    mutation.mutate({ ...data, token });
  };

  if (!token) {
    return (
      <Card>
        <div className="text-center">
          <h2 className="mb-2 text-xl font-semibold text-gray-900">
            Enlace inválido
          </h2>
          <p className="mb-6 text-sm text-gray-600">
            El enlace de recuperación no es válido o ha expirado. Solicita uno nuevo.
          </p>
          <Link
            href="/forgot-password"
            className="text-sm font-medium text-violet-600 hover:text-violet-700"
          >
            Solicitar nuevo enlace
          </Link>
        </div>
      </Card>
    );
  }

  return (
    <Card>
      <h2 className="mb-2 text-center text-xl font-semibold text-gray-900">
        Nueva contraseña
      </h2>
      <p className="mb-6 text-center text-sm text-gray-600">
        Ingresa tu nueva contraseña.
      </p>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Input
          label="Nueva contraseña"
          type="password"
          placeholder="••••••••"
          error={errors.password?.message}
          {...register('password')}
        />

        <Input
          label="Confirmar contraseña"
          type="password"
          placeholder="••••••••"
          error={errors.passwordConfirmation?.message}
          {...register('passwordConfirmation')}
        />

        {mutation.isError && (
          <p className="text-sm text-red-600">
            {(mutation.error as Error)?.message ||
              'El enlace ha expirado o es inválido. Solicita uno nuevo.'}
          </p>
        )}

        <Button
          type="submit"
          fullWidth
          loading={mutation.isPending}
        >
          Actualizar contraseña
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
