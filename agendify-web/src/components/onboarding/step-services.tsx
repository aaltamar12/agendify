'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input, Textarea } from '@/components/ui';
import {
  serviceSchema,
  type ServiceFormData,
} from '@/lib/validations/onboarding';
import { useCreateService } from '@/lib/hooks/use-onboarding';

interface AddedService {
  id?: number;
  name: string;
  price: number;
  duration_minutes: number;
  description?: string;
}

interface StepServicesProps {
  onNext: () => void;
  onBack: () => void;
}

export function StepServices({ onNext, onBack }: StepServicesProps) {
  const [services, setServices] = useState<AddedService[]>([]);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ServiceFormData>({
    resolver: zodResolver(serviceSchema),
    defaultValues: {
      duration_minutes: 30,
    },
  });

  const mutation = useCreateService();

  const onAddService = (data: ServiceFormData) => {
    mutation.mutate(data, {
      onSuccess: (response) => {
        setServices((prev) => [
          ...prev,
          { ...data, id: response.data.id },
        ]);
        reset();
      },
    });
  };

  const removeService = (index: number) => {
    setServices((prev) => prev.filter((_, i) => i !== index));
  };

  const formatPrice = (price: number) =>
    new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency: 'COP',
      minimumFractionDigits: 0,
    }).format(price);

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900">Servicios</h3>
      <p className="text-sm text-gray-500">
        Agrega los servicios que ofreces. Necesitas al menos 1 para continuar.
      </p>

      {/* List of added services */}
      {services.length > 0 && (
        <div className="space-y-2">
          {services.map((service, index) => (
            <div
              key={index}
              className="flex items-center justify-between rounded-lg border border-gray-200 p-3"
            >
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {service.name}
                </p>
                <p className="text-xs text-gray-500">
                  {formatPrice(service.price)} &middot;{' '}
                  {service.duration_minutes} min
                </p>
              </div>
              <button
                type="button"
                onClick={() => removeService(index)}
                className="text-sm text-red-500 hover:text-red-700"
              >
                Eliminar
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Add service form */}
      <form
        onSubmit={handleSubmit(onAddService)}
        className="space-y-3 rounded-lg border border-dashed border-gray-300 p-4"
      >
        <Input
          label="Nombre del servicio"
          placeholder="Ej: Corte de cabello"
          error={errors.name?.message}
          {...register('name')}
        />

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Precio (COP)"
            type="number"
            placeholder="20000"
            error={errors.price?.message}
            {...register('price', { valueAsNumber: true })}
          />
          <Input
            label="Duración (min)"
            type="number"
            placeholder="30"
            error={errors.duration_minutes?.message}
            {...register('duration_minutes', { valueAsNumber: true })}
          />
        </div>

        <Textarea
          label="Descripción (opcional)"
          placeholder="Describe el servicio..."
          rows={2}
          error={errors.description?.message}
          {...register('description')}
        />

        {mutation.isError && (
          <p className="text-sm text-red-600">
            Error al agregar el servicio. Intenta de nuevo.
          </p>
        )}

        <Button
          type="submit"
          variant="outline"
          size="sm"
          loading={mutation.isPending}
        >
          Agregar servicio
        </Button>
      </form>

      <div className="flex items-center justify-between pt-2">
        <Button type="button" variant="ghost" onClick={onBack}>
          Anterior
        </Button>
        <Button
          type="button"
          onClick={onNext}
          disabled={services.length === 0}
        >
          Siguiente
        </Button>
      </div>
    </div>
  );
}
