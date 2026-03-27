'use client';

import { Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button, Input, Card, Spinner } from '@/components/ui';
import { useInvitationDetails, useAcceptInvitation } from '@/lib/hooks/use-employee-dashboard';
import { useAuthStore } from '@/lib/stores/auth-store';

const schema = z.object({
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres'),
  password_confirmation: z.string().min(1, 'Confirma tu contraseña'),
}).refine((d) => d.password === d.password_confirmation, {
  message: 'Las contraseñas no coinciden',
  path: ['password_confirmation'],
});

type FormData = z.infer<typeof schema>;

export default function EmployeeRegisterPage() {
  return (
    <Suspense>
      <EmployeeRegisterForm />
    </Suspense>
  );
}

function EmployeeRegisterForm() {
  const searchParams = useSearchParams();
  const token = searchParams.get('token') || '';
  const router = useRouter();
  const setAuth = useAuthStore((s) => s.setAuth);

  const { data: invitation, isLoading } = useInvitationDetails(token);
  const acceptMutation = useAcceptInvitation();

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  if (!token) {
    return (
      <Card>
        <p className="text-center text-gray-500">Enlace de invitación inválido.</p>
      </Card>
    );
  }

  if (isLoading) {
    return <div className="flex justify-center py-12"><Spinner size="lg" /></div>;
  }

  if (!invitation) {
    return (
      <Card>
        <p className="text-center text-gray-500">Invitación no encontrada.</p>
      </Card>
    );
  }

  if (invitation.expired) {
    return (
      <Card>
        <h2 className="mb-2 text-center text-xl font-semibold text-gray-900">Invitación expirada</h2>
        <p className="text-center text-sm text-gray-500">Pide al negocio que te envíe una nueva invitación.</p>
      </Card>
    );
  }

  if (invitation.accepted) {
    return (
      <Card>
        <h2 className="mb-2 text-center text-xl font-semibold text-gray-900">Invitación ya aceptada</h2>
        <p className="text-center text-sm text-gray-500">Ya tienes una cuenta. Inicia sesión.</p>
      </Card>
    );
  }

  const onSubmit = async (data: FormData) => {
    try {
      const result = await acceptMutation.mutateAsync({
        token,
        password: data.password,
        password_confirmation: data.password_confirmation,
      });
      const { token: jwt, refresh_token, user } = result.data;
      setAuth(jwt, refresh_token, user as never);
      router.push('/employee');
    } catch {
      // error shown by mutation
    }
  };

  return (
    <Card>
      <div className="mb-6 text-center">
        <h2 className="text-xl font-semibold text-gray-900">Unirte a {invitation.business_name}</h2>
        <p className="mt-1 text-sm text-gray-500">
          Hola {invitation.employee_name}, crea tu contraseña para acceder a tu portal.
        </p>
      </div>

      <div className="mb-4 rounded-lg bg-violet-50 p-3">
        <p className="text-sm text-gray-700"><strong>Nombre:</strong> {invitation.employee_name}</p>
        <p className="text-sm text-gray-700"><strong>Email:</strong> {invitation.email}</p>
        <p className="text-sm text-gray-700"><strong>Negocio:</strong> {invitation.business_name}</p>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Input
          label="Contraseña"
          type="password"
          placeholder="Mínimo 8 caracteres"
          error={errors.password?.message}
          {...register('password')}
        />
        <Input
          label="Confirmar contraseña"
          type="password"
          placeholder="Repite tu contraseña"
          error={errors.password_confirmation?.message}
          {...register('password_confirmation')}
        />

        {acceptMutation.isError && (
          <p className="text-sm text-red-600">
            {(acceptMutation.error as Error)?.message || 'Error al crear la cuenta'}
          </p>
        )}

        <Button type="submit" fullWidth loading={acceptMutation.isPending}>
          Crear cuenta
        </Button>
      </form>
    </Card>
  );
}
