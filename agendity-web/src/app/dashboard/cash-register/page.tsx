'use client';

import React, { useState } from 'react';
import { DollarSign, Users, Calendar, CheckCircle, History, ChevronDown, ChevronRight } from 'lucide-react';
import Link from 'next/link';
import { Button, Card, Spinner } from '@/components/ui';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';
import { useDailySummary, useCloseCashRegister } from '@/lib/hooks/use-cash-register';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useUIStore } from '@/lib/stores/ui-store';
import { ADVANCED_REPORTS_PLANS } from '@/lib/constants';
import type { EmployeePaymentData } from '@/lib/hooks/use-cash-register';

export default function CashRegisterPage() {
  const { planSlug } = useCurrentSubscription();
  const hasAccess = ADVANCED_REPORTS_PLANS.includes(planSlug);

  if (!hasAccess) {
    return (
      <div>
        <h1 className="mb-6 text-2xl font-bold text-gray-900">Cierre de caja</h1>
        <UpgradeBanner feature="cierre de caja" targetPlan="Profesional" />
      </div>
    );
  }

  return <CashRegisterContent />;
}

function CashRegisterContent() {
  const today = new Date().toISOString().split('T')[0];
  const [selectedDate, setSelectedDate] = useState(today);
  const { data: summary, isLoading } = useDailySummary(selectedDate);
  const closeMutation = useCloseCashRegister();
  const { addToast } = useUIStore();

  const [payments, setPayments] = useState<Record<number, { amount_paid: number; payment_method: string; notes: string }>>({});
  const [notes, setNotes] = useState('');
  const [expandedEmployee, setExpandedEmployee] = useState<number | null>(null);

  const updatePayment = (employeeId: number, field: string, value: string | number) => {
    setPayments((prev) => ({
      ...prev,
      [employeeId]: { ...prev[employeeId], [field]: value },
    }));
  };

  const handleClose = async () => {
    if (!summary) return;

    const employeePayments: EmployeePaymentData[] = summary.employees.map((emp) => ({
      employee_id: emp.employee_id,
      appointments_count: emp.appointments_count,
      total_earned: emp.total_earned,
      commission_pct: emp.commission_pct,
      commission_amount: emp.commission_amount,
      amount_paid: payments[emp.employee_id]?.amount_paid ?? emp.commission_amount,
      payment_method: payments[emp.employee_id]?.payment_method ?? 'cash',
      notes: payments[emp.employee_id]?.notes ?? '',
    }));

    try {
      await closeMutation.mutateAsync({
        date: selectedDate,
        employee_payments: employeePayments,
        notes,
      });
      addToast({ type: 'success', message: 'Caja cerrada exitosamente' });
    } catch {
      addToast({ type: 'error', message: 'Error al cerrar caja' });
    }
  };

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Cierre de caja</h1>
        <Link href="/dashboard/cash-register/history">
          <Button variant="outline" size="sm">
            <History className="mr-2 h-4 w-4" />
            Historial
          </Button>
        </Link>
      </div>

      {/* Date selector */}
      <div className="mb-6">
        <input
          type="date"
          value={selectedDate}
          max={today}
          onChange={(e) => setSelectedDate(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
        />
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Spinner size="lg" />
        </div>
      ) : !summary ? (
        <p className="text-gray-500">No se pudo cargar el resumen.</p>
      ) : summary.already_closed ? (
        <Card>
          <div className="flex flex-col items-center gap-3 py-8 text-center">
            <CheckCircle className="h-12 w-12 text-green-500" />
            <h2 className="text-lg font-semibold text-gray-900">Caja cerrada</h2>
            <p className="text-sm text-gray-500">
              La caja del {selectedDate} ya fue cerrada.
            </p>
            <Link href="/dashboard/cash-register/history">
              <Button variant="outline" size="sm">Ver en historial</Button>
            </Link>
          </div>
        </Card>
      ) : (
        <>
          {/* Summary cards */}
          <div className="mb-6 grid gap-4 sm:grid-cols-3">
            <Card>
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100">
                  <DollarSign className="h-5 w-5 text-green-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Ingresos</p>
                  <p className="text-xl font-bold text-gray-900">
                    ${summary.total_revenue.toLocaleString()}
                  </p>
                </div>
              </div>
            </Card>
            <Card>
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-violet-100">
                  <Calendar className="h-5 w-5 text-violet-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Citas</p>
                  <p className="text-xl font-bold text-gray-900">{summary.total_appointments}</p>
                </div>
              </div>
            </Card>
            <Card>
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-100">
                  <Users className="h-5 w-5 text-blue-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Empleados</p>
                  <p className="text-xl font-bold text-gray-900">{summary.employees.length}</p>
                </div>
              </div>
            </Card>
          </div>

          {/* Employee breakdown */}
          {summary.employees.length > 0 && (
            <Card className="mb-6">
              <h2 className="mb-4 text-lg font-semibold text-gray-900">Desglose por empleado</h2>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-gray-200 text-left text-gray-500">
                      <th className="pb-3 font-medium">Empleado</th>
                      <th className="pb-3 font-medium">Citas</th>
                      <th className="pb-3 font-medium">Ingresos</th>
                      <th className="pb-3 font-medium">Comisión</th>
                      <th className="pb-3 font-medium">Pago</th>
                      <th className="pb-3 font-medium">Método</th>
                    </tr>
                  </thead>
                  <tbody>
                    {summary.employees.map((emp) => {
                      const isExpanded = expandedEmployee === emp.employee_id;
                      return (
                        <React.Fragment key={emp.employee_id}>
                          <tr
                            className="cursor-pointer border-b border-gray-100 hover:bg-gray-50"
                            onClick={() => setExpandedEmployee(isExpanded ? null : emp.employee_id)}
                          >
                            <td className="py-3 font-medium text-gray-900">
                              <div className="flex items-center gap-2">
                                {isExpanded
                                  ? <ChevronDown className="h-4 w-4 text-gray-400" />
                                  : <ChevronRight className="h-4 w-4 text-gray-400" />
                                }
                                {emp.employee_name}
                              </div>
                            </td>
                            <td className="py-3 text-gray-600">{emp.appointments_count}</td>
                            <td className="py-3 text-gray-600">${emp.total_earned.toLocaleString()}</td>
                            <td className="py-3 text-gray-600">
                              ${emp.commission_amount.toLocaleString()} ({emp.commission_pct}%)
                            </td>
                            <td className="py-3" onClick={(e) => e.stopPropagation()}>
                              <input
                                type="number"
                                defaultValue={emp.commission_amount}
                                onChange={(e) => updatePayment(emp.employee_id, 'amount_paid', parseFloat(e.target.value) || 0)}
                                className="w-28 rounded border border-gray-300 px-2 py-1 text-sm focus:border-violet-500 focus:outline-none"
                              />
                            </td>
                            <td className="py-3" onClick={(e) => e.stopPropagation()}>
                              <select
                                defaultValue="cash"
                                onChange={(e) => updatePayment(emp.employee_id, 'payment_method', e.target.value)}
                                className="rounded border border-gray-300 px-2 py-1 text-sm focus:border-violet-500 focus:outline-none"
                              >
                                <option value="cash">Efectivo</option>
                                <option value="transfer">Transferencia</option>
                              </select>
                            </td>
                          </tr>
                          {/* Expanded detail: appointment list */}
                          {isExpanded && emp.appointments && (
                            <tr>
                              <td colSpan={6} className="bg-gray-50 px-4 pb-3 pt-1">
                                <table className="w-full text-xs">
                                  <thead>
                                    <tr className="text-left text-gray-400">
                                      <th className="pb-1 font-medium">Hora</th>
                                      <th className="pb-1 font-medium">Cliente</th>
                                      <th className="pb-1 font-medium">Servicio</th>
                                      <th className="pb-1 font-medium text-right">Valor</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                    {emp.appointments.map((appt) => (
                                      <tr key={appt.id} className="border-b border-gray-100 last:border-0">
                                        <td className="py-1.5 text-gray-600">{appt.start_time}</td>
                                        <td className="py-1.5 text-gray-700">{appt.customer_name}</td>
                                        <td className="py-1.5 text-gray-600">{appt.service_name}</td>
                                        <td className="py-1.5 text-right font-medium text-gray-900">
                                          ${appt.price.toLocaleString()}
                                        </td>
                                      </tr>
                                    ))}
                                  </tbody>
                                </table>
                              </td>
                            </tr>
                          )}
                        </React.Fragment>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </Card>
          )}

          {/* Notes and close */}
          <Card>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Notas u observaciones del día (opcional)..."
              rows={3}
              className="mb-4 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
            />
            <div className="flex justify-end">
              <Button
                onClick={handleClose}
                loading={closeMutation.isPending}
                disabled={summary.total_appointments === 0}
              >
                Cerrar caja del día
              </Button>
            </div>
          </Card>
        </>
      )}
    </div>
  );
}
