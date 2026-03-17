'use client';

import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input } from '@/components/ui';
import {
  businessHoursSchema,
  type BusinessHoursFormData,
} from '@/lib/validations/onboarding';
import { useUpdateBusinessHours } from '@/lib/hooks/use-onboarding';

const DAY_NAMES = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const DEFAULT_HOURS: BusinessHoursFormData['hours'] = Array.from(
  { length: 7 },
  (_, i) => ({
    day_of_week: i,
    open_time: '08:00',
    close_time: '18:00',
    enabled: i < 6, // Mon-Sat enabled, Sunday disabled
  }),
);

interface StepBusinessHoursProps {
  onNext: () => void;
  onBack: () => void;
  onSkip: () => void;
}

export function StepBusinessHours({
  onNext,
  onBack,
  onSkip,
}: StepBusinessHoursProps) {
  const { register, handleSubmit, control, watch } =
    useForm<BusinessHoursFormData>({
      resolver: zodResolver(businessHoursSchema),
      defaultValues: {
        hours: DEFAULT_HOURS,
      },
    });

  const { fields } = useFieldArray({
    control,
    name: 'hours',
  });

  const mutation = useUpdateBusinessHours();
  const hoursValues = watch('hours');

  const onSubmit = (data: BusinessHoursFormData) => {
    mutation.mutate(data, {
      onSuccess: () => onNext(),
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900">
        Horario de atención
      </h3>
      <p className="text-sm text-gray-500">
        Configura los días y horas en que atiendes.
      </p>

      <div className="space-y-3">
        {fields.map((field, index) => {
          const isEnabled = hoursValues?.[index]?.enabled;
          return (
            <div
              key={field.id}
              className="flex items-center gap-3 rounded-lg border border-gray-200 p-3"
            >
              <label className="flex w-28 shrink-0 items-center gap-2 text-sm font-medium text-gray-700">
                <input
                  type="checkbox"
                  className="h-4 w-4 rounded border-gray-300 text-violet-600 focus:ring-violet-500"
                  {...register(`hours.${index}.enabled`)}
                />
                {DAY_NAMES[index]}
              </label>

              <input type="hidden" {...register(`hours.${index}.day_of_week`, { valueAsNumber: true })} />

              <Input
                type="time"
                disabled={!isEnabled}
                className="w-auto"
                {...register(`hours.${index}.open_time`)}
              />

              <span className="text-sm text-gray-400">a</span>

              <Input
                type="time"
                disabled={!isEnabled}
                className="w-auto"
                {...register(`hours.${index}.close_time`)}
              />
            </div>
          );
        })}
      </div>

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
