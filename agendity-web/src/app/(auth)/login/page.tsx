'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input, Card } from '@/components/ui';
import { loginSchema, type LoginFormData } from '@/lib/validations/auth';
import { useLogin } from '@/lib/hooks/use-auth';

export default function LoginPage() {
  const searchParams = useSearchParams();
  const resetSuccess = searchParams.get('reset') === 'success';

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  const loginMutation = useLogin();

  const onSubmit = (data: LoginFormData) => {
    loginMutation.mutate(data);
  };

  return (
    <Card>
      <h2 className="mb-6 text-center text-xl font-semibold text-gray-900">
        Iniciar sesión
      </h2>

      {resetSuccess && (
        <div className="mb-4 rounded-md bg-green-50 p-3 text-sm text-green-700">
          Contraseña actualizada exitosamente. Inicia sesión con tu nueva contraseña.
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
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
          placeholder="••••••••"
          error={errors.password?.message}
          {...register('password')}
        />

        {loginMutation.isError && (
          <p className="text-sm text-red-600">
            {(loginMutation.error as Error)?.message ||
              'Credenciales inválidas. Intenta de nuevo.'}
          </p>
        )}

        <Button
          type="submit"
          fullWidth
          loading={loginMutation.isPending}
        >
          Iniciar sesión
        </Button>
      </form>

      <div className="mt-3 text-center">
        <Link
          href="/forgot-password"
          className="text-sm font-medium text-violet-600 hover:text-violet-700"
        >
          ¿Olvidaste tu contraseña?
        </Link>
      </div>

      <p className="mt-4 text-center text-sm text-gray-600">
        ¿No tienes cuenta?{' '}
        <Link
          href="/register"
          className="font-medium text-violet-600 hover:text-violet-700"
        >
          Regístrate
        </Link>
      </p>
    </Card>
  );
}
