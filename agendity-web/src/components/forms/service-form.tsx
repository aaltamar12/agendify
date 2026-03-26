'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button, Input, Textarea, Select } from '@/components/ui';
import { useServiceCategories } from '@/lib/hooks/use-services';
import type { Service } from '@/lib/api/types';

const serviceFormSchema = z.object({
  name: z.string().min(1, 'El nombre es requerido'),
  description: z.string().optional(),
  price: z
    .number({ error: 'Ingresa un precio válido' })
    .positive('El precio debe ser mayor a 0'),
  duration_minutes: z
    .number({ error: 'Selecciona una duración' })
    .min(15, 'Mínimo 15 minutos'),
  active: z.boolean(),
  category: z.string().optional(),
});

type ServiceFormData = z.infer<typeof serviceFormSchema>;

const durationOptions = [
  { value: '15', label: '15 minutos' },
  { value: '30', label: '30 minutos' },
  { value: '45', label: '45 minutos' },
  { value: '60', label: '1 hora' },
  { value: '90', label: '1 hora 30 min' },
  { value: '120', label: '2 horas' },
];

interface ServiceFormProps {
  service?: Service | null;
  onSubmit: (data: ServiceFormData) => void;
  loading?: boolean;
}

export function ServiceForm({ service, onSubmit, loading }: ServiceFormProps) {
  const { data: categories = [] } = useServiceCategories();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ServiceFormData>({
    resolver: zodResolver(serviceFormSchema),
    defaultValues: {
      name: service?.name ?? '',
      description: service?.description ?? '',
      price: service?.price ?? 0,
      duration_minutes: service?.duration_minutes ?? 30,
      active: service?.active ?? true,
      category: service?.category ?? '',
    },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <Input
        label="Nombre del servicio"
        placeholder="Ej: Corte clásico"
        error={errors.name?.message}
        {...register('name')}
      />

      <Textarea
        label="Descripción (opcional)"
        placeholder="Describe el servicio..."
        rows={3}
        error={errors.description?.message}
        {...register('description')}
      />

      <div>
        <label className="mb-1.5 block text-sm font-medium text-gray-700">
          Categoría (opcional)
        </label>
        <input
          list="categories-list"
          placeholder="Ej: Corte, Barba, Combo..."
          className="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400 transition-colors focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
          {...register('category')}
        />
        <datalist id="categories-list">
          {categories.map((cat) => (
            <option key={cat} value={cat} />
          ))}
        </datalist>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            Precio (COP)
          </label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">
              $
            </span>
            <input
              type="number"
              min={0}
              step={500}
              placeholder="25000"
              className="block w-full rounded-lg border border-gray-300 bg-white py-2 pl-7 pr-3 text-sm text-gray-900 placeholder:text-gray-400 transition-colors focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
              {...register('price', { valueAsNumber: true })}
            />
          </div>
          {errors.price && (
            <p className="mt-1.5 text-sm text-red-600">{errors.price.message}</p>
          )}
        </div>

        <Select
          label="Duración"
          options={durationOptions}
          error={errors.duration_minutes?.message}
          {...register('duration_minutes', { valueAsNumber: true })}
        />
      </div>

      {/* Active toggle */}
      <div className="flex items-center gap-3">
        <label className="relative inline-flex cursor-pointer items-center">
          <input
            type="checkbox"
            className="peer sr-only"
            {...register('active')}
          />
          <div className="h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:bg-white after:transition-all peer-checked:bg-violet-600 peer-checked:after:translate-x-full" />
        </label>
        <span className="text-sm text-gray-700">Servicio activo</span>
      </div>

      <div className="flex justify-end gap-3 pt-2">
        <Button type="submit" loading={loading}>
          {service ? 'Guardar cambios' : 'Crear servicio'}
        </Button>
      </div>
    </form>
  );
}
