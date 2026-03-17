'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useQuery } from '@tanstack/react-query';
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

  const {
    register,
    handleSubmit,
    watch,
    reset,
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

  // Reset form when modal opens with new defaults
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

  // Filter employees that offer the selected service (if we have the data)
  // For now, show all active employees — the API handles service-employee mapping
  const filteredEmployees = employees.filter((e) => e.active);

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
          <h3 className="mb-3 text-sm font-semibold text-gray-700">
            Fecha y hora
          </h3>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <Input
              label="Fecha"
              type="date"
              error={errors.appointment_date?.message}
              {...register('appointment_date')}
            />
            <Input
              label="Hora"
              type="time"
              step="900"
              error={errors.start_time?.message}
              {...register('start_time')}
            />
          </div>
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
