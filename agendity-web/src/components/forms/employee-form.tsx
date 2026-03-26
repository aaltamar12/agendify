'use client';

import { useRef, useState } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Camera, AlertTriangle } from 'lucide-react';
import { Button, Input, Select, Avatar } from '@/components/ui';
import { useServices } from '@/lib/hooks/use-services';
import { useUploadEmployeeAvatar } from '@/lib/hooks/use-employees';
import { DAYS_OF_WEEK } from '@/lib/constants';
import type { Employee, EmployeeSchedule } from '@/lib/api/types';

// Time options every 30 minutes from 06:00 to 22:00
const TIME_OPTIONS: string[] = [];
for (let h = 6; h <= 22; h++) {
  for (const m of [0, 30]) {
    if (h === 22 && m === 30) break;
    TIME_OPTIONS.push(`${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`);
  }
}

const scheduleEntrySchema = z.object({
  day_of_week: z.number(),
  start_time: z.string(),
  end_time: z.string(),
  active: z.boolean(),
});

const employeeFormSchema = z.object({
  name: z.string().min(1, 'El nombre es requerido'),
  phone: z.string().optional(),
  email: z
    .string()
    .email('Ingresa un correo válido')
    .optional()
    .or(z.literal('')),
  active: z.boolean(),
  payment_type: z.enum(['manual', 'commission', 'fixed_daily']).default('manual'),
  commission_percentage: z.coerce.number().min(0).max(100).optional().default(0),
  fixed_daily_pay: z.coerce.number().int('Debe ser un valor entero').min(0).optional().default(0),
  service_ids: z.array(z.number()),
  schedules: z.array(scheduleEntrySchema),
});

type EmployeeFormData = z.infer<typeof employeeFormSchema>;

// Default schedule: Mon-Sat 08:00-18:00, Sunday off
// DAYS_OF_WEEK is ordered Mon(1)..Sat(6), Dom(0)
const buildDefaultSchedules = (
  existing?: EmployeeSchedule[]
): EmployeeFormData['schedules'] => {
  return DAYS_OF_WEEK.map((day) => {
    const found = existing?.find((s) => s.day_of_week === day.value);
    if (found) {
      return {
        day_of_week: found.day_of_week,
        start_time: found.start_time.slice(0, 5), // ensure "HH:MM"
        end_time: found.end_time.slice(0, 5),
        active: found.active,
      };
    }
    return {
      day_of_week: day.value,
      start_time: '08:00',
      end_time: '18:00',
      active: day.value !== 0, // Sunday off
    };
  });
};

interface EmployeeFormProps {
  employee?: (Employee & { service_ids?: number[]; schedules?: EmployeeSchedule[] }) | null;
  onSubmit: (data: EmployeeFormData) => void;
  loading?: boolean;
}

export function EmployeeForm({ employee, onSubmit, loading }: EmployeeFormProps) {
  const { data: services } = useServices();
  const uploadAvatar = useUploadEmployeeAvatar();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(employee?.avatar_url || null);

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !employee?.id) return;

    setAvatarPreview(URL.createObjectURL(file));
    uploadAvatar.mutate({ id: employee.id, file });
  };

  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
    control,
  } = useForm<EmployeeFormData>({
    resolver: zodResolver(employeeFormSchema) as any,
    defaultValues: {
      name: employee?.name ?? '',
      phone: employee?.phone ?? '',
      email: employee?.email ?? '',
      active: employee?.active ?? true,
      payment_type: employee?.payment_type ?? 'manual',
      commission_percentage: employee?.commission_percentage ?? 0,
      fixed_daily_pay: employee?.fixed_daily_pay ?? 0,
      service_ids: employee?.service_ids ?? [],
      schedules: buildDefaultSchedules(employee?.schedules),
    },
  });

  const watchPaymentType = watch('payment_type');

  const { fields } = useFieldArray({
    control,
    name: 'schedules',
  });

  const selectedServiceIds = watch('service_ids');
  const schedulesValues = watch('schedules');

  const toggleService = (serviceId: number) => {
    const current = selectedServiceIds;
    if (current.includes(serviceId)) {
      setValue(
        'service_ids',
        current.filter((id) => id !== serviceId)
      );
    } else {
      setValue('service_ids', [...current, serviceId]);
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      {/* Avatar upload */}
      <div className="flex items-center gap-4">
        <div className="relative">
          <Avatar
            name={watch('name') || 'E'}
            src={avatarPreview || undefined}
            size="xl"
          />
          {employee?.id && (
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="absolute -bottom-1 -right-1 flex h-7 w-7 items-center justify-center rounded-full bg-violet-600 text-white shadow-sm hover:bg-violet-700"
            >
              <Camera className="h-3.5 w-3.5" />
            </button>
          )}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleAvatarChange}
          />
        </div>
        <div className="text-sm text-gray-500">
          {employee?.id
            ? 'Haz clic en el icono para cambiar la foto'
            : 'Podrás agregar una foto después de crear el empleado'}
        </div>
      </div>

      <Input
        label="Nombre"
        placeholder="Ej: Carlos Pérez"
        error={errors.name?.message}
        {...register('name')}
      />

      <div className="grid grid-cols-2 gap-4">
        <Input
          label="Teléfono"
          placeholder="300 123 4567"
          error={errors.phone?.message}
          {...register('phone')}
        />
        <Input
          label="Correo electrónico"
          type="email"
          placeholder="correo@ejemplo.com"
          error={errors.email?.message}
          {...register('email')}
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
        <span className="text-sm text-gray-700">Empleado activo</span>
      </div>

      {/* Payment type */}
      <Select
        label="Tipo de pago"
        options={[
          { value: 'manual', label: 'Sin pago configurado (manual)' },
          { value: 'commission', label: 'Comisión (% sobre servicios)' },
          { value: 'fixed_daily', label: 'Pago fijo diario ($)' },
        ]}
        {...register('payment_type')}
      />

      {watchPaymentType === 'manual' && (
        <p className="!mt-1 flex items-center gap-1.5 text-xs text-amber-600">
          <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
          Se recomienda configurar una comisión o pago fijo para un mejor control en el cierre de caja.
        </p>
      )}

      {watchPaymentType === 'commission' && (
        <Input
          label="Comisión (%)"
          type="number"
          min={0}
          max={100}
          step={1}
          placeholder="Ej: 30"
          error={errors.commission_percentage?.message}
          {...register('commission_percentage')}
        />
      )}

      {watchPaymentType === 'fixed_daily' && (
        <Input
          label="Pago fijo diario ($)"
          type="number"
          min={0}
          step={1}
          placeholder="Ej: 50000"
          error={errors.fixed_daily_pay?.message}
          {...register('fixed_daily_pay')}
        />
      )}

      {/* Service assignment */}
      {services && services.length > 0 && (
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-700">
            Servicios asignados
          </label>
          <div className="max-h-48 space-y-2 overflow-y-auto rounded-lg border border-gray-200 p-3">
            {services.map((service) => (
              <label
                key={service.id}
                className="flex cursor-pointer items-center gap-2"
              >
                <input
                  type="checkbox"
                  checked={selectedServiceIds.includes(service.id)}
                  onChange={() => toggleService(service.id)}
                  className="h-4 w-4 rounded border-gray-300 text-violet-600 focus:ring-violet-600"
                />
                <span className="text-sm text-gray-700">{service.name}</span>
              </label>
            ))}
          </div>
        </div>
      )}

      {/* Employee work schedule */}
      <div>
        <label className="mb-2 block text-sm font-medium text-gray-700">
          Horario de trabajo
        </label>
        <p className="mb-3 text-xs text-gray-500">
          Configura los días y horas en que trabaja este empleado.
        </p>
        <div className="space-y-2">
          {fields.map((field, index) => {
            const dayInfo = DAYS_OF_WEEK[index];
            const isActive = schedulesValues?.[index]?.active;
            return (
              <div
                key={field.id}
                className="flex items-center gap-3 rounded-lg border border-gray-200 p-3"
              >
                <label className="flex w-28 shrink-0 items-center gap-2 text-sm font-medium text-gray-700">
                  <input
                    type="checkbox"
                    className="h-4 w-4 rounded border-gray-300 text-violet-600 focus:ring-violet-500"
                    {...register(`schedules.${index}.active`)}
                  />
                  {dayInfo.label}
                </label>

                <input
                  type="hidden"
                  {...register(`schedules.${index}.day_of_week`, { valueAsNumber: true })}
                />

                <select
                  disabled={!isActive}
                  className="rounded-lg border border-gray-300 bg-white px-2 py-1.5 pr-8 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20 disabled:bg-gray-50 disabled:opacity-50"
                  {...register(`schedules.${index}.start_time`)}
                >
                  {TIME_OPTIONS.map((t) => (
                    <option key={t} value={t}>
                      {t}
                    </option>
                  ))}
                </select>

                <span className="text-sm text-gray-400">a</span>

                <select
                  disabled={!isActive}
                  className="rounded-lg border border-gray-300 bg-white px-2 py-1.5 pr-8 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20 disabled:bg-gray-50 disabled:opacity-50"
                  {...register(`schedules.${index}.end_time`)}
                >
                  {TIME_OPTIONS.map((t) => (
                    <option key={t} value={t}>
                      {t}
                    </option>
                  ))}
                </select>
              </div>
            );
          })}
        </div>
      </div>

      <div className="flex justify-end gap-3 pt-2">
        <Button type="submit" loading={loading}>
          {employee ? 'Guardar cambios' : 'Crear empleado'}
        </Button>
      </div>
    </form>
  );
}
