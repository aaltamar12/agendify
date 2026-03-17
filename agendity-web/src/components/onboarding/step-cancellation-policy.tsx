'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Select, Input } from '@/components/ui';
import {
  cancellationPolicySchema,
  type CancellationPolicyFormData,
} from '@/lib/validations/onboarding';
import { useCompleteOnboarding, useUpdateBusinessProfile } from '@/lib/hooks/use-onboarding';

const policyOptions = [
  { value: '0', label: 'Sin penalización (0%)' },
  { value: '30', label: '30% del valor del servicio' },
  { value: '50', label: '50% del valor del servicio' },
  { value: '100', label: '100% del valor del servicio' },
];

interface StepCancellationPolicyProps {
  onBack: () => void;
}

export function StepCancellationPolicy({
  onBack,
}: StepCancellationPolicyProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<CancellationPolicyFormData>({
    resolver: zodResolver(cancellationPolicySchema),
    defaultValues: {
      cancellation_policy_pct: '0',
      cancellation_deadline_hours: 24,
    },
  });

  const updateMutation = useUpdateBusinessProfile();
  const completeMutation = useCompleteOnboarding();

  const onSubmit = (data: CancellationPolicyFormData) => {
    updateMutation.mutate(data as never, {
      onSuccess: () => {
        completeMutation.mutate();
      },
    });
  };

  const isLoading = updateMutation.isPending || completeMutation.isPending;

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900">
        Política de cancelación
      </h3>
      <p className="text-sm text-gray-500">
        Define qué pasa si un cliente cancela su cita.
      </p>

      <Select
        label="Penalización por cancelación"
        options={policyOptions}
        error={errors.cancellation_policy_pct?.message}
        {...register('cancellation_policy_pct')}
      />

      <Input
        label="Horas límite para cancelar"
        type="number"
        placeholder="24"
        error={errors.cancellation_deadline_hours?.message}
        {...register('cancellation_deadline_hours', { valueAsNumber: true })}
      />

      <p className="text-xs text-gray-400">
        Si el cliente cancela con menos de estas horas de anticipación, se
        aplicará la penalización.
      </p>

      {(updateMutation.isError || completeMutation.isError) && (
        <p className="text-sm text-red-600">
          Error al guardar. Intenta de nuevo.
        </p>
      )}

      <div className="flex items-center justify-between pt-2">
        <Button type="button" variant="ghost" onClick={onBack}>
          Anterior
        </Button>
        <Button type="submit" loading={isLoading}>
          Completar configuración
        </Button>
      </div>
    </form>
  );
}
