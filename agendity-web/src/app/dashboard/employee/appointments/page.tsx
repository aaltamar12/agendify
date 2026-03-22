'use client';

import { useState } from 'react';
import { Card, Spinner, Badge } from '@/components/ui';
import { useEmployeeAppointments } from '@/lib/hooks/use-employee-dashboard';

const STATUS_LABELS: Record<string, { label: string; variant: 'default' | 'success' | 'destructive' }> = {
  pending_payment: { label: 'Pendiente pago', variant: 'default' },
  payment_sent: { label: 'Comprobante enviado', variant: 'default' },
  confirmed: { label: 'Confirmada', variant: 'default' },
  checked_in: { label: 'Check-in', variant: 'success' },
  completed: { label: 'Completada', variant: 'success' },
  cancelled: { label: 'Cancelada', variant: 'destructive' },
};

export default function EmployeeAppointmentsPage() {
  const [dateFilter, setDateFilter] = useState('');
  const { data: appointments, isLoading } = useEmployeeAppointments(
    dateFilter ? { date: dateFilter } : undefined,
  );

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Mis citas</h1>
        <input
          type="date"
          value={dateFilter}
          onChange={(e) => setDateFilter(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
        />
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12"><Spinner size="lg" /></div>
      ) : !appointments || appointments.length === 0 ? (
        <Card>
          <p className="py-8 text-center text-gray-500">
            {dateFilter ? 'No tienes citas para esta fecha.' : 'No tienes citas registradas.'}
          </p>
        </Card>
      ) : (
        <div className="space-y-3">
          {appointments.map((appt) => {
            const statusInfo = STATUS_LABELS[appt.status] || { label: appt.status, variant: 'default' as const };
            return (
              <Card key={appt.id}>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-900">
                      {appt.customer?.name || 'Cliente'} — {appt.service?.name}
                    </p>
                    <p className="text-xs text-gray-500">
                      {appt.appointment_date} · {appt.start_time?.toString().slice(0, 5)}
                      {appt.price && ` · $${Number(appt.price).toLocaleString()}`}
                    </p>
                  </div>
                  <Badge variant={statusInfo.variant}>{statusInfo.label}</Badge>
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
