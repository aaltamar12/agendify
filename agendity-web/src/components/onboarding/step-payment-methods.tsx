'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input } from '@/components/ui';
import {
  paymentMethodsSchema,
  type PaymentMethodsFormData,
} from '@/lib/validations/onboarding';
import { useUpdateBusinessProfile } from '@/lib/hooks/use-onboarding';

interface StepPaymentMethodsProps {
  onNext: () => void;
  onBack: () => void;
  onSkip: () => void;
}

export function StepPaymentMethods({
  onNext,
  onBack,
  onSkip,
}: StepPaymentMethodsProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<PaymentMethodsFormData>({
    resolver: zodResolver(paymentMethodsSchema),
  });

  const mutation = useUpdateBusinessProfile();

  const onSubmit = (data: PaymentMethodsFormData) => {
    mutation.mutate(data as never, {
      onSuccess: () => onNext(),
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900">Métodos de pago</h3>
      <p className="text-sm text-gray-500">
        Configura cómo tus clientes pueden pagarte. Agrega al menos uno.
      </p>

      <Input
        label="Nequi (número de teléfono)"
        placeholder="300 123 4567"
        error={errors.nequi_phone?.message}
        {...register('nequi_phone')}
      />

      <Input
        label="Daviplata (número de teléfono)"
        placeholder="300 123 4567"
        error={errors.daviplata_phone?.message}
        {...register('daviplata_phone')}
      />

      <Input
        label="Cuenta Bancolombia"
        placeholder="Número de cuenta"
        error={errors.bancolombia_account?.message}
        {...register('bancolombia_account')}
      />

      {mutation.isError && (
        <p className="text-sm text-red-600">
          Error al guardar. Intenta de nuevo.
        </p>
      )}

      <div className="flex items-center justify-between pt-2">
        <Button type="button" variant="ghost" onClick={onBack}>
          Anterior
        </Button>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={onSkip}
            className="text-sm text-gray-500 hover:text-gray-700"
          >
            Saltar
          </button>
          <Button type="submit" loading={mutation.isPending}>
            Siguiente
          </Button>
        </div>
      </div>
    </form>
  );
}
