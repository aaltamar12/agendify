'use client';

import { useState } from 'react';
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
  const [showCustomCategory, setShowCustomCategory] = useState(false);
  const [customDuration, setCustomDuration] = useState(
    !!service?.duration_minutes && !durationOptions.some((o) => Number(o.value) === service.duration_minutes)
  );
  const [durationUnit, setDurationUnit] = useState<'min' | 'hrs'>('min');

  const {
    register,
    handleSubmit,
    setValue,
    watch,
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
        {!showCustomCategory ? (
          <select
            className="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 transition-colors focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
            value={watch('category') ?? ''}
            onChange={(e) => {
              if (e.target.value === '__new__') {
                setShowCustomCategory(true);
                setValue('category', '');
              } else {
                setValue('category', e.target.value);
              }
            }}
          >
            <option value="">Sin categoría</option>
            {categories.map((cat) => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
            <option value="__new__">+ Nueva categoría...</option>
          </select>
        ) : (
          <div className="flex gap-2">
            <input
              type="text"
              placeholder="Nombre de la categoría"
              autoFocus
              className="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400 transition-colors focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
              {...register('category')}
            />
            <button
              type="button"
              onClick={() => { setShowCustomCategory(false); setValue('category', ''); }}
              className="shrink-0 rounded-lg border border-gray-300 px-3 py-2 text-xs text-gray-500 hover:bg-gray-50"
            >
              Cancelar
            </button>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
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

        <div>
          <div className="mb-1.5 flex items-center justify-between">
            <label className="text-sm font-medium text-gray-700">Duración</label>
            <label className="flex items-center gap-1.5 cursor-pointer">
              <span className="text-xs text-gray-500">Personalizada</span>
              <input
                type="checkbox"
                checked={customDuration}
                onChange={(e) => {
                  setCustomDuration(e.target.checked);
                  if (!e.target.checked) {
                    setValue('duration_minutes', 30);
                    setDurationUnit('min');
                  }
                }}
                className="h-3.5 w-3.5 rounded border-gray-300 text-violet-600 focus:ring-violet-600"
              />
            </label>
          </div>
          {!customDuration ? (
            <select
              className="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 transition-colors focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
              {...register('duration_minutes', { valueAsNumber: true })}
            >
              {durationOptions.map((o) => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </select>
          ) : (
            <div className="flex gap-2">
              <input
                type="number"
                min={1}
                placeholder={durationUnit === 'min' ? '45' : '2'}
                className="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400 transition-colors focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
                value={durationUnit === 'hrs' ? Math.round((watch('duration_minutes') || 60) / 60) : (watch('duration_minutes') || 30)}
                onChange={(e) => {
                  const val = Number(e.target.value) || 0;
                  setValue('duration_minutes', durationUnit === 'hrs' ? val * 60 : val);
                }}
              />
              <select
                value={durationUnit}
                onChange={(e) => {
                  const newUnit = e.target.value as 'min' | 'hrs';
                  const current = watch('duration_minutes') || 30;
                  if (newUnit === 'hrs' && durationUnit === 'min') {
                    setValue('duration_minutes', Math.round(current / 60) * 60 || 60);
                  }
                  setDurationUnit(newUnit);
                }}
                className="w-24 shrink-0 rounded-lg border border-gray-300 bg-white px-2 py-2 text-sm text-gray-700 focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
              >
                <option value="min">min</option>
                <option value="hrs">hrs</option>
              </select>
            </div>
          )}
          {errors.duration_minutes && (
            <p className="mt-1.5 text-sm text-red-600">{errors.duration_minutes.message}</p>
          )}
        </div>
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
