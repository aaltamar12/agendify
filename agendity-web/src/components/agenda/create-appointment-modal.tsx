'use client';

import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useQuery } from '@tanstack/react-query';
import { Clock } from 'lucide-react';
import { Modal } from '@/components/ui/modal';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Service, Employee } from '@/lib/api/types';
import {
  createAppointmentSchema,
  type CreateAppointmentFormData,
} from '@/lib/validations/appointment';
import { useCreateAppointment } from '@/lib/hooks/use-appointments';
import { useUIStore } from '@/lib/stores/ui-store';

interface Slot {
  time: string;
  available: boolean;
}

interface CreateAppointmentModalProps {
  open: boolean;
  onClose: () => void;
  defaultDate?: string;
  defaultTime?: string;
}

export function CreateAppointmentModal({
  open,
  onClose,
  defaultDate,
  defaultTime,
}: CreateAppointmentModalProps) {
  const addToast = useUIStore((s) => s.addToast);
  const createAppointment = useCreateAppointment();
  const [manualTime, setManualTime] = useState(false);

  const {
    register,
    handleSubmit,
    watch,
    reset,
    setValue,
    formState: { errors },
  } = useForm<CreateAppointmentFormData>({
    resolver: zodResolver(createAppointmentSchema),
    defaultValues: {
      appointment_date: defaultDate ?? '',
      start_time: defaultTime ?? '',
      notes: '',
      customer_email: '',
    },
  });

  useEffect(() => {
    if (open) {
      reset({
        appointment_date: defaultDate ?? '',
        start_time: defaultTime ?? '',
        notes: '',
        customer_email: '',
        service_id: undefined,
        employee_id: undefined,
        customer_name: '',
        customer_phone: '',
      });
      setManualTime(false);
    }
  }, [open, defaultDate, defaultTime, reset]);

  // Fetch services
  const { data: servicesData } = useQuery({
    queryKey: ['services'],
    queryFn: () => get<ApiResponse<Service[]>>(ENDPOINTS.SERVICES.list),
    enabled: open,
  });

  // Fetch employees
  const { data: employeesData } = useQuery({
    queryKey: ['employees'],
    queryFn: () => get<ApiResponse<Employee[]>>(ENDPOINTS.EMPLOYEES.list),
    enabled: open,
  });

  const services = servicesData?.data ?? [];
  const employees = employeesData?.data ?? [];
  const selectedServiceId = watch('service_id');
  const selectedEmployeeId = watch('employee_id');
  const selectedDate = watch('appointment_date');
  const selectedTime = watch('start_time');

  const filteredEmployees = employees.filter((e) => e.active);

  // Fetch available slots when service + date are selected
  const slotsEnabled = !!(selectedServiceId && selectedDate && !manualTime);
  const { data: slotsData, isLoading: slotsLoading } = useQuery({
    queryKey: ['available-slots', selectedServiceId, selectedEmployeeId, selectedDate],
    queryFn: () =>
      get<ApiResponse<Slot[]>>(ENDPOINTS.APPOINTMENTS.availableSlots, {
        params: {
          service_id: selectedServiceId,
          employee_id: selectedEmployeeId || undefined,
          date: selectedDate,
        },
      }),
    enabled: slotsEnabled,
  });

  const slots = slotsData?.data ?? [];

  const serviceOptions = services
    .filter((s) => s.active)
    .map((s) => ({
      value: String(s.id),
      label: `${s.name} (${s.duration_minutes} min - $${s.price.toLocaleString()})`,
    }));

  const employeeOptions = filteredEmployees.map((e) => ({
    value: String(e.id),
    label: e.name,
  }));

  async function onSubmit(data: CreateAppointmentFormData) {
    try {
      await createAppointment.mutateAsync(data);
      addToast({ type: 'success', message: 'Cita creada exitosamente' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al crear la cita' });
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Nueva cita" size="lg">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        {/* Service */}
        <Select
          label="Servicio"
          placeholder="Selecciona un servicio"
          options={serviceOptions}
          error={errors.service_id?.message}
          {...register('service_id', { valueAsNumber: true })}
        />

        {/* Employee */}
        <Select
          label="Empleado"
          placeholder="Selecciona un empleado"
          options={employeeOptions}
          error={errors.employee_id?.message}
          disabled={!selectedServiceId}
          {...register('employee_id', { valueAsNumber: true })}
        />

        {/* Customer info */}
        <div className="border-t border-gray-200 pt-4">
          <h3 className="mb-3 text-sm font-semibold text-gray-700">
            Datos del cliente
          </h3>
          <div className="space-y-3">
            <Input
              label="Nombre"
              placeholder="Nombre del cliente"
              error={errors.customer_name?.message}
              {...register('customer_name')}
            />
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <Input
                label="Teléfono"
                placeholder="3001234567"
                type="tel"
                error={errors.customer_phone?.message}
                {...register('customer_phone')}
              />
              <Input
                label="Correo (opcional)"
                placeholder="correo@ejemplo.com"
                type="email"
                error={errors.customer_email?.message}
                {...register('customer_email')}
              />
            </div>
          </div>
        </div>

        {/* Date and time */}
        <div className="border-t border-gray-200 pt-4">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-sm font-semibold text-gray-700">
              Fecha y hora
            </h3>
            <button
              type="button"
              onClick={() => setManualTime(!manualTime)}
              className="text-xs font-medium text-violet-600 hover:text-violet-700"
            >
              {manualTime ? 'Ver horarios disponibles' : 'Ingresar hora manual'}
            </button>
          </div>

          <Input
            label="Fecha"
            type="date"
            error={errors.appointment_date?.message}
            {...register('appointment_date')}
          />

          {manualTime ? (
            <div className="mt-3">
              <Input
                label="Hora"
                type="time"
                step="900"
                error={errors.start_time?.message}
                {...register('start_time')}
              />
            </div>
          ) : (
            <div className="mt-3">
              {!selectedServiceId || !selectedDate ? (
                <p className="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">
                  <Clock className="h-4 w-4" />
                  Selecciona un servicio y fecha para ver horarios disponibles
                </p>
              ) : slotsLoading ? (
                <div className="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-violet-600 border-t-transparent" />
                  Cargando horarios...
                </div>
              ) : slots.length === 0 ? (
                <p className="rounded-lg border border-orange-200 bg-orange-50 p-3 text-sm text-orange-700">
                  No hay horarios disponibles para esta fecha.
                </p>
              ) : (
                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Horarios disponibles
                  </label>
                  <div className="grid grid-cols-4 gap-2 sm:grid-cols-6">
                    {slots.map((slot) => (
                      <button
                        key={slot.time}
                        type="button"
                        disabled={!slot.available}
                        onClick={() => setValue('start_time', slot.time, { shouldValidate: true })}
                        className={`rounded-lg border px-2 py-2 text-sm font-medium transition-colors ${
                          !slot.available
                            ? 'cursor-not-allowed border-gray-100 bg-gray-50 text-gray-300'
                            : selectedTime === slot.time
                              ? 'border-violet-600 bg-violet-600 text-white'
                              : 'border-gray-200 bg-white text-gray-700 hover:border-violet-300 hover:bg-violet-50'
                        }`}
                      >
                        {slot.time}
                      </button>
                    ))}
                  </div>
                  {errors.start_time && (
                    <p className="mt-1 text-sm text-red-600">{errors.start_time.message}</p>
                  )}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Notes */}
        <Textarea
          label="Notas (opcional)"
          placeholder="Notas adicionales sobre la cita..."
          rows={3}
          {...register('notes')}
        />

        {/* Actions */}
        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <Button type="button" variant="ghost" onClick={onClose}>
            Cancelar
          </Button>
          <Button type="submit" loading={createAppointment.isPending}>
            Crear cita
          </Button>
        </div>
      </form>
    </Modal>
  );
}
