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
import type { ApiResponse, Employee } from '@/lib/api/types';
import {
  blockSlotSchema,
  type BlockSlotFormData,
} from '@/lib/validations/appointment';
import { useCreateBlockedSlot } from '@/lib/hooks/use-blocked-slots';
import { useUIStore } from '@/lib/stores/ui-store';

interface BlockSlotModalProps {
  open: boolean;
  onClose: () => void;
  defaultDate?: string;
  defaultTime?: string;
}

export function BlockSlotModal({
  open,
  onClose,
  defaultDate,
  defaultTime,
}: BlockSlotModalProps) {
  const addToast = useUIStore((s) => s.addToast);
  const createBlockedSlot = useCreateBlockedSlot();

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<BlockSlotFormData>({
    resolver: zodResolver(blockSlotSchema),
    defaultValues: {
      date: defaultDate ?? '',
      start_time: defaultTime ?? '',
      end_time: '',
      reason: '',
    },
  });

  // Reset form when modal opens
  useEffect(() => {
    if (open) {
      reset({
        date: defaultDate ?? '',
        start_time: defaultTime ?? '',
        end_time: '',
        reason: '',
        employee_id: undefined,
      });
    }
  }, [open, defaultDate, defaultTime, reset]);

  // Fetch employees
  const { data: employeesData } = useQuery({
    queryKey: ['employees'],
    queryFn: () => get<ApiResponse<Employee[]>>(ENDPOINTS.EMPLOYEES.list),
    enabled: open,
  });

  const employees = employeesData?.data ?? [];

  const employeeOptions = [
    { value: '', label: 'Todo el negocio' },
    ...employees
      .filter((e) => e.active)
      .map((e) => ({
        value: String(e.id),
        label: e.name,
      })),
  ];

  async function onSubmit(data: BlockSlotFormData) {
    try {
      await createBlockedSlot.mutateAsync(data);
      addToast({ type: 'success', message: 'Horario bloqueado exitosamente' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al bloquear el horario' });
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Bloquear horario" size="md">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        {/* Employee (optional) */}
        <Select
          label="Empleado"
          options={employeeOptions}
          error={errors.employee_id?.message}
          {...register('employee_id', {
            setValueAs: (v: string) => (v ? Number(v) : undefined),
          })}
        />

        {/* Date */}
        <Input
          label="Fecha"
          type="date"
          error={errors.date?.message}
          {...register('date')}
        />

        {/* Start/end time */}
        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Hora inicio"
            type="time"
            step="900"
            error={errors.start_time?.message}
            {...register('start_time')}
          />
          <Input
            label="Hora fin"
            type="time"
            step="900"
            error={errors.end_time?.message}
            {...register('end_time')}
          />
        </div>

        {/* Reason */}
        <Textarea
          label="Motivo (opcional)"
          placeholder="Ej: Almuerzo, capacitación, mantenimiento..."
          rows={2}
          {...register('reason')}
        />

        {/* Actions */}
        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <Button type="button" variant="ghost" onClick={onClose}>
            Cancelar
          </Button>
          <Button type="submit" loading={createBlockedSlot.isPending}>
            Bloquear
          </Button>
        </div>
      </form>
    </Modal>
  );
}
