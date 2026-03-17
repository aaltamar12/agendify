'use client';

import { useState } from 'react';
import {
  User,
  Phone,
  Mail,
  Clock,
  Calendar,
  Scissors,
  DollarSign,
  MessageSquare,
} from 'lucide-react';
import { Modal } from '@/components/ui/modal';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import type { Appointment, AppointmentStatus } from '@/lib/api/types';
import { APPOINTMENT_STATUSES } from '@/lib/constants';
import { formatDate, formatTime } from '@/lib/utils/date';
import { formatCurrency, formatPhone } from '@/lib/utils/format';
import {
  useCancelAppointment,
  useConfirmPayment,
  useCheckinAppointment,
  useCompleteAppointment,
} from '@/lib/hooks/use-appointments';
import { useUIStore } from '@/lib/stores/ui-store';

interface AppointmentDetailModalProps {
  open: boolean;
  onClose: () => void;
  appointment: Appointment | null;
}

const statusBadgeVariant: Record<
  AppointmentStatus,
  'default' | 'success' | 'warning' | 'error' | 'info'
> = {
  pending_payment: 'warning',
  payment_sent: 'info',
  confirmed: 'success',
  checked_in: 'info',
  cancelled: 'error',
  completed: 'default',
};

export function AppointmentDetailModal({
  open,
  onClose,
  appointment,
}: AppointmentDetailModalProps) {
  const addToast = useUIStore((s) => s.addToast);
  const [cancelLoading, setCancelLoading] = useState(false);

  const confirmPayment = useConfirmPayment(appointment?.id ?? 0);
  const checkinAppointment = useCheckinAppointment(appointment?.id ?? 0);
  const completeAppointment = useCompleteAppointment(appointment?.id ?? 0);
  const cancelAppointment = useCancelAppointment();

  if (!appointment) return null;

  const status = APPOINTMENT_STATUSES[appointment.status];

  async function handleConfirmPayment() {
    try {
      await confirmPayment.mutateAsync();
      addToast({ type: 'success', message: 'Pago confirmado exitosamente' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al confirmar el pago' });
    }
  }

  async function handleCheckin() {
    try {
      await checkinAppointment.mutateAsync();
      addToast({ type: 'success', message: 'Check-in realizado' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al realizar check-in' });
    }
  }

  async function handleComplete() {
    try {
      await completeAppointment.mutateAsync();
      addToast({ type: 'success', message: 'Cita completada' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al completar la cita' });
    }
  }

  async function handleCancel() {
    if (!appointment) return;
    setCancelLoading(true);
    try {
      await cancelAppointment.mutateAsync({
        id: appointment.id,
        cancelled_by: 'business',
      });
      addToast({ type: 'success', message: 'Cita cancelada' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al cancelar la cita' });
    } finally {
      setCancelLoading(false);
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Detalle de cita" size="md">
      <div className="space-y-4">
        {/* Status badge */}
        <Badge variant={statusBadgeVariant[appointment.status]}>
          {status.label}
        </Badge>

        {/* Customer info */}
        <div className="space-y-2">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
            Cliente
          </h3>
          <div className="space-y-1.5">
            {appointment.customer && (
              <>
                <div className="flex items-center gap-2 text-sm text-gray-700">
                  <User className="h-4 w-4 text-gray-400" />
                  <span>{appointment.customer.name}</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-700">
                  <Phone className="h-4 w-4 text-gray-400" />
                  <span>{formatPhone(appointment.customer.phone)}</span>
                </div>
                {appointment.customer.email && (
                  <div className="flex items-center gap-2 text-sm text-gray-700">
                    <Mail className="h-4 w-4 text-gray-400" />
                    <span>{appointment.customer.email}</span>
                  </div>
                )}
              </>
            )}
          </div>
        </div>

        {/* Service info */}
        <div className="space-y-2">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
            Servicio
          </h3>
          <div className="space-y-1.5">
            {appointment.service && (
              <div className="flex items-center gap-2 text-sm text-gray-700">
                <Scissors className="h-4 w-4 text-gray-400" />
                <span>{appointment.service.name}</span>
                <span className="text-gray-400">
                  ({appointment.service.duration_minutes} min)
                </span>
              </div>
            )}
            <div className="flex items-center gap-2 text-sm text-gray-700">
              <DollarSign className="h-4 w-4 text-gray-400" />
              <span>{formatCurrency(appointment.price)}</span>
            </div>
          </div>
        </div>

        {/* Employee info */}
        {appointment.employee && (
          <div className="space-y-2">
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
              Empleado
            </h3>
            <div className="flex items-center gap-2 text-sm text-gray-700">
              <User className="h-4 w-4 text-gray-400" />
              <span>{appointment.employee.name}</span>
            </div>
          </div>
        )}

        {/* Date/time info */}
        <div className="space-y-2">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
            Fecha y hora
          </h3>
          <div className="space-y-1.5">
            <div className="flex items-center gap-2 text-sm text-gray-700">
              <Calendar className="h-4 w-4 text-gray-400" />
              <span>{formatDate(appointment.date)}</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-700">
              <Clock className="h-4 w-4 text-gray-400" />
              <span>
                {formatTime(appointment.start_time)} -{' '}
                {formatTime(appointment.end_time)}
              </span>
            </div>
          </div>
        </div>

        {/* Cancellation info */}
        {appointment.status === 'cancelled' && appointment.cancelled_by && (
          <div className="space-y-2">
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
              Cancelación
            </h3>
            <div className="text-sm text-gray-700">
              <span>
                Cancelada por:{' '}
                <span className="font-medium">
                  {appointment.cancelled_by === 'business'
                    ? 'el negocio'
                    : 'el cliente'}
                </span>
              </span>
            </div>
          </div>
        )}

        {/* Notes */}
        {appointment.notes && (
          <div className="space-y-2">
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
              Notas
            </h3>
            <div className="flex items-start gap-2 text-sm text-gray-700">
              <MessageSquare className="mt-0.5 h-4 w-4 text-gray-400" />
              <span>{appointment.notes}</span>
            </div>
          </div>
        )}

        {/* Action buttons */}
        <div className="flex flex-wrap gap-2 border-t border-gray-200 pt-4">
          {/* Pending payment → Confirm */}
          {appointment.status === 'pending_payment' && (
            <Button
              onClick={handleConfirmPayment}
              loading={confirmPayment.isPending}
              size="sm"
            >
              Confirmar pago
            </Button>
          )}

          {/* Payment sent → Approve / Reject */}
          {appointment.status === 'payment_sent' && (
            <>
              <Button
                onClick={handleConfirmPayment}
                loading={confirmPayment.isPending}
                size="sm"
              >
                Aprobar pago
              </Button>
              <Button
                variant="destructive"
                onClick={handleCancel}
                loading={cancelLoading}
                size="sm"
              >
                Rechazar pago
              </Button>
            </>
          )}

          {/* Confirmed → Check-in */}
          {appointment.status === 'confirmed' && (
            <Button
              onClick={handleCheckin}
              loading={checkinAppointment.isPending}
              size="sm"
            >
              Check-in
            </Button>
          )}

          {/* Checked in → Complete */}
          {appointment.status === 'checked_in' && (
            <Button
              onClick={handleComplete}
              loading={completeAppointment.isPending}
              size="sm"
            >
              Completar
            </Button>
          )}

          {/* Cancel button for non-final statuses */}
          {appointment.status !== 'cancelled' &&
            appointment.status !== 'completed' && (
              <Button
                variant="destructive"
                onClick={handleCancel}
                loading={cancelLoading}
                size="sm"
              >
                Cancelar cita
              </Button>
            )}
        </div>
      </div>
    </Modal>
  );
}
