'use client';

import { useState } from 'react';
import { ShieldCheck, AlertTriangle, CheckCircle, Search, Sparkles, DollarSign } from 'lucide-react';
import { Button, Card, Spinner, Modal, Input } from '@/components/ui';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';
import { useReconciliationCheck, useAdjustEmployeeBalance } from '@/lib/hooks/use-reconciliation';
import { useEmployees } from '@/lib/hooks/use-employees';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useUIStore } from '@/lib/stores/ui-store';
import { AI_FEATURES_PLANS } from '@/lib/constants';
import type { ReconciliationResult, Discrepancy } from '@/lib/hooks/use-reconciliation';

export default function ReconciliationPage() {
  const { planSlug } = useCurrentSubscription();
  const hasAI = AI_FEATURES_PLANS.includes(planSlug);

  if (!hasAI) {
    return (
      <div>
        <h1 className="mb-6 text-2xl font-bold text-gray-900">Reconciliacion</h1>
        <UpgradeBanner feature="reconciliacion contable" targetPlan="Inteligente" />
      </div>
    );
  }

  return <ReconciliationContent />;
}

function ReconciliationContent() {
  const reconciliationMutation = useReconciliationCheck();
  const { data: employees } = useEmployees();
  const { addToast } = useUIStore();
  const [adjustModal, setAdjustModal] = useState<{ id: number; name: string } | null>(null);
  const [result, setResult] = useState<ReconciliationResult | null>(null);

  const handleCheck = async () => {
    try {
      const res = await reconciliationMutation.mutateAsync();
      setResult(res.data);
    } catch {
      addToast({ type: 'error', message: 'Error al ejecutar reconciliacion' });
    }
  };

  const cashOk = result?.cash_register?.ok !== false;
  const creditsOk = result?.credits?.ok !== false;

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900">Reconciliacion</h1>
          <Sparkles className="h-5 w-5 text-amber-500" />
        </div>
        <Button onClick={handleCheck} loading={reconciliationMutation.isPending}>
          <ShieldCheck className="mr-2 h-4 w-4" />
          Verificar consistencia
        </Button>
      </div>

      {!result ? (
        <Card>
          <div className="py-8 text-center">
            <ShieldCheck className="mx-auto mb-3 h-12 w-12 text-gray-300" />
            <p className="text-gray-500">Ejecuta una verificacion para comprobar que los saldos de empleados y creditos de clientes son consistentes.</p>
          </div>
        </Card>
      ) : (
        <div className="space-y-6">
          {/* Cash register reconciliation */}
          <Card>
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900">Saldos de empleados</h2>
              {cashOk ? (
                <span className="flex items-center gap-1.5 rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">
                  <CheckCircle className="h-3.5 w-3.5" /> Todo correcto
                </span>
              ) : (
                <span className="flex items-center gap-1.5 rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-700">
                  <AlertTriangle className="h-3.5 w-3.5" /> {result.cash_register.discrepancies.length} discrepancia(s)
                </span>
              )}
            </div>

            {!cashOk && result.cash_register.discrepancies.length > 0 && (
              <DiscrepancyTable
                items={result.cash_register.discrepancies}
                type="employee"
                onAdjust={(d) => setAdjustModal({ id: d.employee_id || d.id, name: d.employee_name || d.name || '—' })}
              />
            )}
          </Card>

          {/* Credits reconciliation */}
          <Card>
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900">Creditos de clientes</h2>
              {creditsOk ? (
                <span className="flex items-center gap-1.5 rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">
                  <CheckCircle className="h-3.5 w-3.5" /> Todo correcto
                </span>
              ) : (
                <span className="flex items-center gap-1.5 rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-700">
                  <AlertTriangle className="h-3.5 w-3.5" /> {result.credits.discrepancies.length} discrepancia(s)
                </span>
              )}
            </div>

            {!creditsOk && result.credits.discrepancies.length > 0 && (
              <DiscrepancyTable
                items={result.credits.discrepancies}
                type="credit"
              />
            )}
          </Card>

          {/* Employee balance adjustments */}
          <Card>
            <h2 className="mb-4 text-lg font-semibold text-gray-900">Ajustar saldo de empleado</h2>
            <p className="mb-4 text-sm text-gray-500">Selecciona un empleado para ajustar su saldo pendiente manualmente.</p>
            <div className="flex flex-wrap gap-2">
              {employees?.map((emp) => (
                <button
                  key={emp.id}
                  type="button"
                  onClick={() => setAdjustModal({ id: emp.id, name: emp.name })}
                  className="cursor-pointer rounded-lg border border-gray-200 px-3 py-2 text-sm hover:border-violet-300 hover:bg-violet-50"
                >
                  {emp.name}
                  {(emp.pending_balance ?? 0) > 0 && (
                    <span className="ml-2 text-xs text-orange-600">${Number(emp.pending_balance ?? 0).toLocaleString()}</span>
                  )}
                </button>
              ))}
            </div>
          </Card>
        </div>
      )}

      {adjustModal && (
        <AdjustBalanceModal
          employeeId={adjustModal.id}
          employeeName={adjustModal.name}
          onClose={() => setAdjustModal(null)}
        />
      )}
    </div>
  );
}

function DiscrepancyTable({ items, type, onAdjust }: { items: Discrepancy[]; type: 'employee' | 'credit'; onAdjust?: (d: Discrepancy) => void }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-gray-200 text-left text-gray-500">
            <th className="pb-2 font-medium">{type === 'employee' ? 'Empleado' : 'Cliente'}</th>
            <th className="pb-2 font-medium text-right">Esperado</th>
            <th className="pb-2 font-medium text-right">Actual</th>
            <th className="pb-2 font-medium text-right">Diferencia</th>
            {onAdjust && <th className="pb-2 pl-4 font-medium">Accion</th>}
          </tr>
        </thead>
        <tbody>
          {items.map((d, idx) => (
            <tr key={d.id || d.employee_id || d.credit_account_id || idx} className="border-b border-gray-100">
              <td className="py-2 font-medium text-gray-900">{d.employee_name || d.customer_name || d.name || '—'}</td>
              <td className="py-2 text-right text-gray-600">${d.expected.toLocaleString()}</td>
              <td className="py-2 text-right text-gray-600">${d.actual.toLocaleString()}</td>
              <td className={`py-2 text-right font-bold ${d.difference > 0 ? 'text-red-600' : 'text-green-600'}`}>
                {d.difference > 0 ? '+' : ''}{d.difference.toLocaleString()}
              </td>
              {onAdjust && (
                <td className="py-2 pl-4">
                  <button
                    type="button"
                    onClick={() => onAdjust(d)}
                    className="cursor-pointer text-xs font-medium text-violet-600 hover:text-violet-700"
                  >
                    Ajustar
                  </button>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function AdjustBalanceModal({ employeeId, employeeName, onClose }: { employeeId: number; employeeName: string; onClose: () => void }) {
  const [amount, setAmount] = useState('');
  const [reason, setReason] = useState('');
  const [notes, setNotes] = useState('');
  const adjustMutation = useAdjustEmployeeBalance();
  const { addToast } = useUIStore();

  const reasons = ['Correccion de error', 'Deuda perdonada', 'Ajuste por acuerdo', 'Otro'];

  const handleSubmit = async () => {
    const amt = parseFloat(amount);
    if (!amt || !reason) return;
    try {
      await adjustMutation.mutateAsync({ employeeId, amount: amt, reason, notes });
      addToast({ type: 'success', message: `Saldo ajustado para ${employeeName}` });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al ajustar saldo' });
    }
  };

  return (
    <Modal open onClose={onClose} title={`Ajustar saldo — ${employeeName}`}>
      <div className="space-y-4">
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Monto</label>
          <p className="mb-1 text-xs text-gray-400">Positivo = se le debe mas, negativo = perdonar/corregir</p>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="Ej: -5000 (perdonar) o 3000 (agregar deuda)"
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
          />
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Razon *</label>
          <select
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
          >
            <option value="">Seleccionar razon</option>
            {reasons.map((r) => <option key={r} value={r}>{r}</option>)}
          </select>
        </div>

        <Input
          label="Notas (opcional)"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Detalles adicionales..."
        />

        <div className="flex justify-end gap-3">
          <Button variant="ghost" onClick={onClose}>Cancelar</Button>
          <Button onClick={handleSubmit} loading={adjustMutation.isPending} disabled={!parseFloat(amount) || !reason}>
            <DollarSign className="mr-1.5 h-4 w-4" />
            Aplicar ajuste
          </Button>
        </div>
      </div>
    </Modal>
  );
}
