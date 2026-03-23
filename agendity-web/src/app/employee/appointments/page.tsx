'use client';

import { useState } from 'react';
import { Card, Spinner } from '@/components/ui';
import { useEmployeeAppointments } from '@/lib/hooks/use-employee-dashboard';
import { formatCurrency } from '@/lib/utils/format';

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  pending_payment: { label: 'Pendiente pago', color: 'bg-orange-100 text-orange-700' },
  payment_sent: { label: 'Comprobante enviado', color: 'bg-blue-100 text-blue-700' },
  confirmed: { label: 'Confirmada', color: 'bg-green-100 text-green-700' },
  checked_in: { label: 'En atencion', color: 'bg-violet-100 text-violet-700' },
  completed: { label: 'Completada', color: 'bg-gray-100 text-gray-600' },
  cancelled: { label: 'Cancelada', color: 'bg-red-100 text-red-700' },
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
                      {appt.price && ` · ${formatCurrency(Number(appt.price))}`}
                    </p>
                  </div>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${statusInfo.color}`}>
                    {statusInfo.label}
                  </span>
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
