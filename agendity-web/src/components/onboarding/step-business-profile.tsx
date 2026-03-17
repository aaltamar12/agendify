'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input, Textarea, Select } from '@/components/ui';
import {
  businessProfileSchema,
  type BusinessProfileFormData,
} from '@/lib/validations/onboarding';
import { useUpdateBusinessProfile } from '@/lib/hooks/use-onboarding';
import { useCountries, useStates, useCities } from '@/lib/hooks/use-locations';

interface StepBusinessProfileProps {
  onNext: () => void;
}

export function StepBusinessProfile({ onNext }: StepBusinessProfileProps) {
  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm<BusinessProfileFormData>({
    resolver: zodResolver(businessProfileSchema),
    defaultValues: {
      country: 'CO',
      state: 'ATL',
      city: 'Barranquilla',
    },
  });

  const mutation = useUpdateBusinessProfile();

  const watchedCountry = watch('country');
  const watchedState = watch('state');
  const { data: countriesData } = useCountries();
  const { data: statesData } = useStates(watchedCountry ?? '');
  const { data: citiesData } = useCities(watchedCountry ?? '', watchedState ?? '');

  const onSubmit = (data: BusinessProfileFormData) => {
    mutation.mutate(data, {
      onSuccess: () => onNext(),
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900">
        Perfil del negocio
      </h3>
      <p className="text-sm text-gray-500">
        Completa la información básica de tu negocio.
      </p>

      <Input
        label="Nombre del negocio"
        placeholder="Ej: Barbería Don Juan"
        error={errors.name?.message}
        {...register('name')}
      />

      <Input
        label="Teléfono"
        type="tel"
        placeholder="300 123 4567"
        error={errors.phone?.message}
        {...register('phone')}
      />

      <Input
        label="Dirección"
        placeholder="Calle 72 #45-10"
        error={errors.address?.message}
        {...register('address')}
      />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Select
          key={`country-${countriesData?.data?.length ?? 0}`}
          label="País"
          options={[
            { value: '', label: 'Seleccionar...' },
            ...(countriesData?.data?.map((c) => ({
              value: c.code!,
              label: c.name,
            })) ?? []),
          ]}
          error={errors.country?.message}
          {...register('country', {
            onChange: () => {
              setValue('state', '');
              setValue('city', '');
            },
          })}
        />
        <Select
          key={`state-${statesData?.data?.length ?? 0}`}
          label="Departamento"
          options={[
            { value: '', label: 'Seleccionar...' },
            ...(statesData?.data?.map((s) => ({
              value: s.code!,
              label: s.name,
            })) ?? []),
          ]}
          error={errors.state?.message}
          {...register('state', {
            onChange: () => {
              setValue('city', '');
            },
          })}
        />
        <Select
          key={`city-${citiesData?.data?.length ?? 0}`}
          label="Ciudad"
          options={[
            { value: '', label: 'Seleccionar...' },
            ...(citiesData?.data?.map((c) => ({
              value: c.name,
              label: c.name,
            })) ?? []),
          ]}
          error={errors.city?.message}
          {...register('city')}
        />
      </div>

      <Textarea
        label="Descripción (opcional)"
        placeholder="Cuéntale a tus clientes sobre tu negocio..."
        rows={3}
        error={errors.description?.message}
        {...register('description')}
      />

      <Input
        label="Instagram (opcional)"
        placeholder="https://instagram.com/tunegocio"
        error={errors.instagram_url?.message}
        {...register('instagram_url')}
      />

      <Input
        label="Facebook (opcional)"
        placeholder="https://facebook.com/tunegocio"
        error={errors.facebook_url?.message}
        {...register('facebook_url')}
      />

      {mutation.isError && (
        <p className="text-sm text-red-600">
          Error al guardar. Intenta de nuevo.
        </p>
      )}

      <div className="flex justify-end pt-2">
        <Button type="submit" loading={mutation.isPending}>
          Siguiente
        </Button>
      </div>
    </form>
  );
}
