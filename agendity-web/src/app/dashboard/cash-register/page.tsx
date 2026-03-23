'use client';

import React, { useState, useRef } from 'react';
import {
  DollarSign, Users, Calendar, CheckCircle, History,
  ChevronDown, ChevronRight, Upload, Check, X, AlertTriangle, Paperclip,
} from 'lucide-react';
import Link from 'next/link';
import { Button, Card, Spinner } from '@/components/ui';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';
import { useDailySummary, useCloseCashRegister } from '@/lib/hooks/use-cash-register';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useUIStore } from '@/lib/stores/ui-store';
import { ADVANCED_REPORTS_PLANS } from '@/lib/constants';
import type { EmployeePaymentData, EmployeeSummary } from '@/lib/hooks/use-cash-register';

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

interface PaymentState {
  method: 'cash' | 'transfer';
  confirmed: boolean;
  proofFile: File | null;
  proofPreview: string | null;
  amount_paid: number;
  notes: string;
}

function CashRegisterContent() {
  const today = new Date().toISOString().split('T')[0];
  const [selectedDate, setSelectedDate] = useState(today);
  const { data: summary, isLoading } = useDailySummary(selectedDate);
  const closeMutation = useCloseCashRegister();
  const { addToast } = useUIStore();

  const [payments, setPayments] = useState<Record<number, PaymentState>>({});
  const [notes, setNotes] = useState('');
  const [expandedEmployee, setExpandedEmployee] = useState<number | null>(null);

  const getPaymentState = (emp: EmployeeSummary): PaymentState => {
    return payments[emp.employee_id] || {
      method: 'cash',
      confirmed: false,
      proofFile: null,
      proofPreview: null,
      amount_paid: emp.total_owed,
      notes: '',
    };
  };

  const updatePaymentState = (employeeId: number, updates: Partial<PaymentState>) => {
    setPayments((prev) => ({
      ...prev,
      [employeeId]: { ...getPaymentStateById(employeeId), ...updates },
    }));
  };

  const getPaymentStateById = (employeeId: number): PaymentState => {
    const emp = summary?.employees.find((e) => e.employee_id === employeeId);
    return payments[employeeId] || {
      method: 'cash',
      confirmed: false,
      proofFile: null,
      proofPreview: null,
      amount_paid: emp?.total_owed ?? 0,
      notes: '',
    };
  };

  const handleClose = async () => {
    if (!summary) return;

    const employeePayments: EmployeePaymentData[] = summary.employees.map((emp) => {
      const state = getPaymentState(emp);
      const isConfirmed = state.method === 'cash' ? state.confirmed : !!state.proofFile;
      return {
        employee_id: emp.employee_id,
        appointments_count: emp.appointments_count,
        total_earned: emp.total_earned,
        commission_pct: emp.commission_pct,
        commission_amount: emp.commission_amount,
        amount_paid: isConfirmed ? state.amount_paid : 0,
        payment_method: state.method,
        notes: state.notes,
      };
    });

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
        <div className="flex justify-center py-12"><Spinner size="lg" /></div>
      ) : !summary ? (
        <p className="text-gray-500">No se pudo cargar el resumen.</p>
      ) : summary.already_closed ? (
        <Card>
          <div className="flex flex-col items-center gap-3 py-8 text-center">
            <CheckCircle className="h-12 w-12 text-green-500" />
            <h2 className="text-lg font-semibold text-gray-900">Caja cerrada</h2>
            <p className="text-sm text-gray-500">La caja del {selectedDate} ya fue cerrada.</p>
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
                  <p className="text-xl font-bold text-gray-900">${summary.total_revenue.toLocaleString()}</p>
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
              <div className="space-y-3">
                {summary.employees.map((emp) => (
                  <EmployeeRow
                    key={emp.employee_id}
                    emp={emp}
                    paymentState={getPaymentState(emp)}
                    isExpanded={expandedEmployee === emp.employee_id}
                    onToggleExpand={() => setExpandedEmployee(expandedEmployee === emp.employee_id ? null : emp.employee_id)}
                    onUpdatePayment={(updates) => updatePaymentState(emp.employee_id, updates)}
                  />
                ))}
              </div>
            </Card>
          )}

          {/* Totals after payments */}
          {summary.employees.length > 0 && (
            <Card className="mb-6">
              <h2 className="mb-4 text-lg font-semibold text-gray-900">Resumen del dia</h2>
              {(() => {
                const totalPaid = summary.employees.reduce((sum, emp) => {
                  const state = getPaymentState(emp);
                  return sum + (state.confirmed ? state.amount_paid : 0);
                }, 0);
                const netProfit = summary.total_revenue - totalPaid;
                return (
                  <div className="flex items-center justify-between">
                    <div className="grid grid-cols-3 gap-8">
                      <div>
                        <p className="text-xs text-gray-500">Ingresos del dia</p>
                        <p className="text-lg font-bold text-gray-900">${summary.total_revenue.toLocaleString()}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Total pagos empleados</p>
                        <p className="text-lg font-bold text-red-600">-${totalPaid.toLocaleString()}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Ganancia neta</p>
                        <p className={`text-lg font-bold ${netProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                          ${netProfit.toLocaleString()}
                        </p>
                      </div>
                    </div>
                  </div>
                );
              })()}
            </Card>
          )}

          {/* Notes and close */}
          <Card>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Notas u observaciones del dia (opcional)..."
              rows={3}
              className="mb-4 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
            />
            <div className="flex justify-end">
              <Button
                onClick={handleClose}
                loading={closeMutation.isPending}
                disabled={summary.total_appointments === 0}
              >
                Cerrar caja del dia
              </Button>
            </div>
          </Card>
        </>
      )}
    </div>
  );
}

function EmployeeRow({
  emp,
  paymentState,
  isExpanded,
  onToggleExpand,
  onUpdatePayment,
}: {
  emp: EmployeeSummary;
  paymentState: PaymentState;
  isExpanded: boolean;
  onToggleExpand: () => void;
  onUpdatePayment: (updates: Partial<PaymentState>) => void;
}) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const hasPending = emp.pending_from_previous > 0;
  const paymentType = emp.payment_type || (emp.commission_pct > 0 ? 'commission' : 'manual');
  const hasCommission = paymentType === 'commission' && emp.commission_pct > 0;
  const hasFixedDaily = paymentType === 'fixed_daily' && (emp.fixed_daily_pay ?? 0) > 0;
  const hasFixedAmount = hasCommission || hasFixedDaily || hasPending;
  const [editingAmount, setEditingAmount] = useState(false);
  const [showDebtModal, setShowDebtModal] = useState(false);

  const handleProofUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    onUpdatePayment({
      proofFile: file,
      proofPreview: URL.createObjectURL(file),
      confirmed: true,
    });
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleRemoveProof = () => {
    onUpdatePayment({
      proofFile: null,
      proofPreview: null,
      confirmed: false,
    });
  };

  const handleCashConfirm = () => {
    onUpdatePayment({ confirmed: true });
  };

  const handleCashUnconfirm = () => {
    onUpdatePayment({ confirmed: false, amount_paid: 0 });
  };

  return (
    <div className="rounded-lg border border-gray-200">
      {/* Main row */}
      <div
        className="flex cursor-pointer items-center gap-3 px-4 py-3 hover:bg-gray-50"
        onClick={onToggleExpand}
      >
        {isExpanded ? <ChevronDown className="h-4 w-4 text-gray-400" /> : <ChevronRight className="h-4 w-4 text-gray-400" />}

        <div className="min-w-0 flex-1">
          <p className="text-sm font-medium text-gray-900">{emp.employee_name}</p>
          <p className="text-xs text-gray-500">
            {emp.appointments_count} cita{emp.appointments_count !== 1 && 's'} · ${emp.total_earned.toLocaleString()} ingresos
          </p>
        </div>

        {/* Payment info */}
        <div className="text-right">
          {hasCommission ? (
            <>
              <p className="text-sm font-medium text-gray-900">${emp.commission_amount.toLocaleString()}</p>
              <p className="text-xs text-gray-500">Comision ({emp.commission_pct}%)</p>
            </>
          ) : hasFixedDaily ? (
            <>
              <p className="text-sm font-medium text-gray-900">${(emp.fixed_daily_pay ?? 0).toLocaleString()}</p>
              <p className="text-xs text-gray-500">Pago fijo diario</p>
            </>
          ) : (
            <p className="text-xs text-gray-400">Sin pago configurado</p>
          )}
        </div>

        {/* Pending badge */}
        {hasPending && (
          <div className="flex items-center gap-1 rounded-full bg-orange-100 px-2 py-0.5">
            <AlertTriangle className="h-3 w-3 text-orange-600" />
            <span className="text-xs font-medium text-orange-700">
              +${emp.pending_from_previous.toLocaleString()} pendiente
            </span>
          </div>
        )}

        {/* Total owed */}
        {(hasCommission || hasPending) ? (
          <div className="text-right">
            <p className="text-sm font-bold text-violet-700">${emp.total_owed.toLocaleString()}</p>
            <p className="text-xs text-gray-500">Total a pagar</p>
          </div>
        ) : paymentState.amount_paid > 0 && paymentState.confirmed ? (
          <div className="text-right">
            <p className="text-sm font-bold text-violet-700">${paymentState.amount_paid.toLocaleString()}</p>
            <p className="text-xs text-gray-500">Pago del dia</p>
          </div>
        ) : null}

        {/* Payment status */}
        <div onClick={(e) => e.stopPropagation()}>
          {paymentState.confirmed ? (
            <div className="flex items-center gap-1 rounded-full bg-green-100 px-2.5 py-1">
              <Check className="h-3.5 w-3.5 text-green-600" />
              <span className="text-xs font-medium text-green-700">Pagado</span>
            </div>
          ) : (
            <div className="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-500">
              Pendiente
            </div>
          )}
        </div>
      </div>

      {/* Expanded content */}
      {isExpanded && (
        <div className="border-t border-gray-100 bg-gray-50 px-4 py-3">
          {/* Appointment details */}
          {emp.appointments && emp.appointments.length > 0 && (
            <div className="mb-4">
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
                      <td className="py-1.5 text-right font-medium text-gray-900">${appt.price.toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Payment section */}
          <div className="rounded-lg border border-gray-200 bg-white p-3">
            {/* Payment method selector */}
            <div className="mb-3 flex items-center gap-3">
              <label className="text-sm font-medium text-gray-700">Metodo de pago:</label>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => onUpdatePayment({ method: 'cash', confirmed: false, proofFile: null, proofPreview: null })}
                  className={`cursor-pointer rounded-lg px-3 py-1.5 text-xs font-medium transition-colors ${
                    paymentState.method === 'cash'
                      ? 'bg-violet-100 text-violet-700'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  Efectivo
                </button>
                <button
                  type="button"
                  onClick={() => onUpdatePayment({ method: 'transfer', confirmed: false, proofFile: null, proofPreview: null })}
                  className={`cursor-pointer rounded-lg px-3 py-1.5 text-xs font-medium transition-colors ${
                    paymentState.method === 'transfer'
                      ? 'bg-violet-100 text-violet-700'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  Transferencia
                </button>
              </div>
            </div>

            {/* Amount section */}
            {hasFixedAmount && !editingAmount ? (
              /* Fixed amount: show confirm button + edit toggle */
              <div>
                {paymentState.confirmed ? (
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Check className="h-4 w-4 text-green-600" />
                      <span className="text-sm text-green-700">
                        Pago confirmado: ${paymentState.amount_paid.toLocaleString()}
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={handleCashUnconfirm}
                      className="cursor-pointer text-xs text-gray-500 hover:text-red-600"
                    >
                      Deshacer
                    </button>
                  </div>
                ) : (
                  <div className="flex items-center gap-3">
                    {paymentState.method === 'cash' ? (
                      <Button size="sm" onClick={handleCashConfirm}>
                        <Check className="mr-1.5 h-4 w-4" />
                        Confirmar pago de ${emp.total_owed.toLocaleString()}
                      </Button>
                    ) : paymentState.proofPreview ? (
                      <div className="flex-1 space-y-2">
                        <div className="flex items-center gap-3">
                          <Paperclip className="h-4 w-4 text-violet-600" />
                          <span className="text-sm text-gray-700">Comprobante adjunto</span>
                          <span className="text-xs font-medium text-green-600">
                            Pago: ${paymentState.amount_paid.toLocaleString()}
                          </span>
                        </div>
                        <img src={paymentState.proofPreview} alt="Comprobante" className="max-h-32 rounded-lg border border-gray-200 object-contain" />
                        <button type="button" onClick={handleRemoveProof} className="flex cursor-pointer items-center gap-1 text-xs text-red-600 hover:text-red-700">
                          <X className="h-3.5 w-3.5" /> Eliminar comprobante
                        </button>
                      </div>
                    ) : (
                      <div>
                        <Button size="sm" variant="outline" onClick={() => fileInputRef.current?.click()}>
                          <Upload className="mr-1.5 h-4 w-4" />
                          Subir comprobante (${emp.total_owed.toLocaleString()})
                        </Button>
                        <input ref={fileInputRef} type="file" accept="image/*" onChange={handleProofUpload} className="hidden" />
                      </div>
                    )}
                    <button
                      type="button"
                      onClick={() => { setEditingAmount(true); onUpdatePayment({ confirmed: false, amount_paid: emp.total_owed }); }}
                      className="cursor-pointer text-xs font-medium text-violet-600 hover:text-violet-700"
                    >
                      Editar monto
                    </button>
                  </div>
                )}
              </div>
            ) : (
              /* Editable amount: input + confirm */
              <div className="space-y-3">
                <div>
                  <div className="mb-1 flex items-center gap-2">
                    <label className="text-xs font-medium text-gray-600">Monto a pagar</label>
                    {hasFixedAmount && (
                      <button
                        type="button"
                        onClick={() => { setEditingAmount(false); onUpdatePayment({ amount_paid: emp.total_owed, confirmed: false }); }}
                        className="cursor-pointer text-xs text-gray-500 hover:text-gray-700"
                      >
                        Cancelar edicion
                      </button>
                    )}
                  </div>
                  <input
                    type="number"
                    min={0}
                    placeholder={hasFixedAmount ? String(emp.total_owed) : 'Ej: 50000'}
                    value={paymentState.amount_paid || ''}
                    onChange={(e) => onUpdatePayment({ amount_paid: parseFloat(e.target.value) || 0, confirmed: false })}
                    className="w-44 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
                  />
                </div>

                {paymentState.confirmed ? (
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Check className="h-4 w-4 text-green-600" />
                      <span className="text-sm text-green-700">
                        Pago confirmado: ${paymentState.amount_paid.toLocaleString()}
                      </span>
                    </div>
                    <button type="button" onClick={handleCashUnconfirm} className="cursor-pointer text-xs text-gray-500 hover:text-red-600">
                      Deshacer
                    </button>
                  </div>
                ) : paymentState.method === 'cash' ? (
                  <Button
                    size="sm"
                    onClick={() => {
                      if (hasFixedAmount && paymentState.amount_paid < emp.total_owed && paymentState.amount_paid > 0) {
                        setShowDebtModal(true);
                      } else {
                        handleCashConfirm();
                      }
                    }}
                    disabled={paymentState.amount_paid <= 0}
                  >
                    <Check className="mr-1.5 h-4 w-4" />
                    {paymentState.amount_paid > 0
                      ? `Confirmar pago de $${paymentState.amount_paid.toLocaleString()}`
                      : 'Ingresa el monto'}
                  </Button>
                ) : paymentState.proofPreview ? (
                  <div className="space-y-2">
                    <div className="flex items-center gap-3">
                      <Paperclip className="h-4 w-4 text-violet-600" />
                      <span className="text-sm text-gray-700">Comprobante adjunto</span>
                    </div>
                    <img src={paymentState.proofPreview} alt="Comprobante" className="max-h-32 rounded-lg border border-gray-200 object-contain" />
                    <button type="button" onClick={handleRemoveProof} className="flex cursor-pointer items-center gap-1 text-xs text-red-600 hover:text-red-700">
                      <X className="h-3.5 w-3.5" /> Eliminar comprobante
                    </button>
                  </div>
                ) : (
                  <div>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        if (hasFixedAmount && paymentState.amount_paid < emp.total_owed && paymentState.amount_paid > 0) {
                          setShowDebtModal(true);
                        } else {
                          fileInputRef.current?.click();
                        }
                      }}
                      disabled={paymentState.amount_paid <= 0}
                    >
                      <Upload className="mr-1.5 h-4 w-4" />
                      Subir comprobante
                    </Button>
                    <input ref={fileInputRef} type="file" accept="image/*" onChange={handleProofUpload} className="hidden" />
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Debt warning modal */}
          {showDebtModal && (
            <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={() => setShowDebtModal(false)}>
              <div className="mx-4 w-full max-w-sm rounded-xl bg-white p-6 shadow-xl" onClick={(e) => e.stopPropagation()}>
                <div className="mb-4 flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-orange-100">
                    <AlertTriangle className="h-5 w-5 text-orange-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900">Pago parcial</h3>
                </div>
                <p className="mb-2 text-sm text-gray-600">
                  Le debes <strong>${emp.total_owed.toLocaleString()}</strong> a {emp.employee_name} y vas a pagar <strong>${paymentState.amount_paid.toLocaleString()}</strong>.
                </p>
                <p className="mb-6 text-sm text-orange-700 font-medium">
                  La diferencia de ${(emp.total_owed - paymentState.amount_paid).toLocaleString()} se sumara como pendiente en el proximo cierre de caja.
                </p>
                <div className="flex justify-end gap-3">
                  <Button variant="ghost" size="sm" onClick={() => setShowDebtModal(false)}>
                    Cancelar
                  </Button>
                  <Button
                    size="sm"
                    onClick={() => {
                      setShowDebtModal(false);
                      if (paymentState.method === 'transfer') {
                        fileInputRef.current?.click();
                      } else {
                        handleCashConfirm();
                      }
                    }}
                  >
                    Confirmar pago parcial
                  </Button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
