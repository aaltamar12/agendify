'use client';

import { useState } from 'react';
import { ArrowLeft, Calendar, DollarSign } from 'lucide-react';
import Link from 'next/link';
import { Button, Card, Spinner, Badge, Modal } from '@/components/ui';
import { useCashRegisterHistory } from '@/lib/hooks/use-cash-register';
import { formatCurrency } from '@/lib/utils/format';
import type { CashRegisterClose } from '@/lib/hooks/use-cash-register';

export default function CashRegisterHistoryPage() {
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const { data: closes, isLoading } = useCashRegisterHistory(
    from || to ? { from: from || undefined, to: to || undefined } : undefined,
  );
  const [selectedClose, setSelectedClose] = useState<CashRegisterClose | null>(null);

  const totalRevenue = closes?.reduce((sum, c) => sum + c.total_revenue, 0) ?? 0;
  const totalAppointments = closes?.reduce((sum, c) => sum + c.total_appointments, 0) ?? 0;

  return (
    <div>
      <div className="mb-6 flex items-center gap-3">
        <Link href="/dashboard/cash-register">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Historial de cierres</h1>
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-wrap gap-3">
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Desde</label>
          <input
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Hasta</label>
          <input
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
          />
        </div>
      </div>

      {/* Summary */}
      {closes && closes.length > 0 && (
        <div className="mb-6 grid gap-4 sm:grid-cols-2">
          <Card>
            <div className="flex items-center gap-3">
              <DollarSign className="h-5 w-5 text-green-600" />
              <div>
                <p className="text-sm text-gray-500">Total ingresos</p>
                <p className="text-xl font-bold text-gray-900">{formatCurrency(totalRevenue)}</p>
              </div>
            </div>
          </Card>
          <Card>
            <div className="flex items-center gap-3">
              <Calendar className="h-5 w-5 text-violet-600" />
              <div>
                <p className="text-sm text-gray-500">Total citas</p>
                <p className="text-xl font-bold text-gray-900">{totalAppointments}</p>
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* Table */}
      {isLoading ? (
        <div className="flex justify-center py-12"><Spinner size="lg" /></div>
      ) : !closes || closes.length === 0 ? (
        <Card>
          <p className="py-8 text-center text-gray-500">No hay cierres de caja registrados.</p>
        </Card>
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 text-left text-gray-500">
                  <th className="pb-3 font-medium">Fecha</th>
                  <th className="pb-3 font-medium">Ingresos</th>
                  <th className="pb-3 font-medium">Citas</th>
                  <th className="pb-3 font-medium">Estado</th>
                  <th className="pb-3 font-medium">Acciones</th>
                </tr>
              </thead>
              <tbody>
                {closes.map((close) => (
                  <tr key={close.id} className="border-b border-gray-100">
                    <td className="py-3 font-medium text-gray-900">{close.date}</td>
                    <td className="py-3 text-gray-600">{formatCurrency(close.total_revenue)}</td>
                    <td className="py-3 text-gray-600">{close.total_appointments}</td>
                    <td className="py-3">
                      <Badge variant={close.status === 'closed' ? 'success' : 'default'}>
                        {close.status === 'closed' ? 'Cerrada' : 'Borrador'}
                      </Badge>
                    </td>
                    <td className="py-3">
                      <button
                        type="button"
                        onClick={() => setSelectedClose(close)}
                        className="cursor-pointer text-sm font-medium text-violet-600 hover:text-violet-700"
                      >
                        Ver detalle
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Detail modal */}
      <Modal
        open={!!selectedClose}
        onClose={() => setSelectedClose(null)}
        title={`Cierre del ${selectedClose?.date}`}
        size="lg"
      >
        {selectedClose && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-500">Ingresos</p>
                <p className="text-lg font-bold">{formatCurrency(selectedClose.total_revenue)}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Citas</p>
                <p className="text-lg font-bold">{selectedClose.total_appointments}</p>
              </div>
            </div>

            {selectedClose.employee_payments && selectedClose.employee_payments.length > 0 && (
              <div>
                <h3 className="mb-2 text-sm font-semibold text-gray-700">Pagos a empleados</h3>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b text-left text-gray-500">
                        <th className="pb-2 font-medium">Empleado</th>
                        <th className="pb-2 font-medium">Ingresos</th>
                        <th className="pb-2 font-medium">Comisión</th>
                        <th className="pb-2 font-medium">Pagado</th>
                        <th className="pb-2 font-medium">Método</th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedClose.employee_payments.map((ep) => (
                        <tr key={ep.employee_id} className="border-b border-gray-50">
                          <td className="py-2 font-medium">{ep.employee_name}</td>
                          <td className="py-2">{formatCurrency(ep.total_earned)}</td>
                          <td className="py-2">{formatCurrency(ep.commission_amount)}</td>
                          <td className="py-2">{formatCurrency(ep.amount_paid)}</td>
                          <td className="py-2 capitalize">{ep.payment_method === 'cash' ? 'Efectivo' : 'Transferencia'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {selectedClose.notes && (
              <div>
                <h3 className="mb-1 text-sm font-semibold text-gray-700">Notas</h3>
                <p className="text-sm text-gray-600">{selectedClose.notes}</p>
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
}
