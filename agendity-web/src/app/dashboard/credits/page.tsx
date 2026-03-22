'use client';

import { useState } from 'react';
import { DollarSign, Plus, Minus, History } from 'lucide-react';
import { Button, Card, Spinner, Modal, Input } from '@/components/ui';
import { useCreditsSummary, useCustomerCredits, useAdjustCredits } from '@/lib/hooks/use-credits';
import { useUIStore } from '@/lib/stores/ui-store';
import type { CreditAccount } from '@/lib/hooks/use-credits';

const TX_TYPE_LABELS: Record<string, { label: string; color: string }> = {
  cashback: { label: 'Cashback', color: 'text-green-600' },
  cancellation_refund: { label: 'Reembolso', color: 'text-blue-600' },
  penalty_deduction: { label: 'Penalizacion', color: 'text-red-600' },
  manual_adjustment: { label: 'Ajuste manual', color: 'text-gray-600' },
  redemption: { label: 'Redencion', color: 'text-orange-600' },
};

export default function CreditsPage() {
  const { data: accounts, isLoading } = useCreditsSummary();
  const [selectedAccount, setSelectedAccount] = useState<CreditAccount | null>(null);
  const [adjustModal, setAdjustModal] = useState<CreditAccount | null>(null);

  const totalCredits = accounts?.reduce((sum, a) => sum + a.balance, 0) ?? 0;

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Creditos de clientes</h1>

      {/* Summary */}
      <Card className="mb-6">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100">
            <DollarSign className="h-5 w-5 text-green-600" />
          </div>
          <div>
            <p className="text-sm text-gray-500">Total creditos en circulacion</p>
            <p className="text-xl font-bold text-gray-900">${totalCredits.toLocaleString()}</p>
          </div>
        </div>
      </Card>

      {/* Accounts table */}
      {isLoading ? (
        <div className="flex justify-center py-12"><Spinner size="lg" /></div>
      ) : !accounts || accounts.length === 0 ? (
        <Card>
          <p className="py-8 text-center text-gray-500">No hay clientes con creditos.</p>
        </Card>
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 text-left text-gray-500">
                  <th className="pb-3 font-medium">Cliente</th>
                  <th className="pb-3 font-medium">Email</th>
                  <th className="pb-3 font-medium text-right">Balance</th>
                  <th className="pb-3 font-medium">Acciones</th>
                </tr>
              </thead>
              <tbody>
                {accounts.map((account) => (
                  <tr key={account.id} className="border-b border-gray-100">
                    <td className="py-3 font-medium text-gray-900">{account.customer_name}</td>
                    <td className="py-3 text-gray-500">{account.customer_email || '—'}</td>
                    <td className="py-3 text-right font-bold text-green-600">${account.balance.toLocaleString()}</td>
                    <td className="py-3">
                      <div className="flex gap-2">
                        <button
                          type="button"
                          onClick={() => setSelectedAccount(account)}
                          className="cursor-pointer text-xs font-medium text-violet-600 hover:text-violet-700"
                        >
                          <History className="mr-1 inline h-3.5 w-3.5" />
                          Historial
                        </button>
                        <button
                          type="button"
                          onClick={() => setAdjustModal(account)}
                          className="cursor-pointer text-xs font-medium text-gray-600 hover:text-gray-700"
                        >
                          Ajustar
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Transaction history modal */}
      {selectedAccount && (
        <TransactionHistoryModal
          account={selectedAccount}
          onClose={() => setSelectedAccount(null)}
        />
      )}

      {/* Adjust modal */}
      {adjustModal && (
        <AdjustCreditsModal
          account={adjustModal}
          onClose={() => setAdjustModal(null)}
        />
      )}
    </div>
  );
}

function TransactionHistoryModal({ account, onClose }: { account: CreditAccount; onClose: () => void }) {
  const { data, isLoading } = useCustomerCredits(account.customer_id);

  return (
    <Modal open onClose={onClose} title={`Creditos — ${account.customer_name}`} size="lg">
      <div className="mb-4 text-center">
        <p className="text-2xl font-bold text-green-600">${account.balance.toLocaleString()}</p>
        <p className="text-xs text-gray-500">Balance actual</p>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-8"><Spinner /></div>
      ) : !data?.transactions?.length ? (
        <p className="py-4 text-center text-sm text-gray-500">No hay transacciones.</p>
      ) : (
        <div className="max-h-80 overflow-y-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left text-gray-500">
                <th className="pb-2 font-medium">Fecha</th>
                <th className="pb-2 font-medium">Tipo</th>
                <th className="pb-2 font-medium">Descripcion</th>
                <th className="pb-2 font-medium text-right">Monto</th>
              </tr>
            </thead>
            <tbody>
              {data.transactions.map((tx) => {
                const info = TX_TYPE_LABELS[tx.transaction_type] || { label: tx.transaction_type, color: 'text-gray-600' };
                return (
                  <tr key={tx.id} className="border-b border-gray-50">
                    <td className="py-2 text-xs text-gray-500">{new Date(tx.created_at).toLocaleDateString()}</td>
                    <td className="py-2">
                      <span className={`text-xs font-medium ${info.color}`}>{info.label}</span>
                    </td>
                    <td className="py-2 text-xs text-gray-600">{tx.description}</td>
                    <td className={`py-2 text-right text-sm font-bold ${tx.amount >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                      {tx.amount >= 0 ? '+' : ''}{tx.amount.toLocaleString()}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </Modal>
  );
}

function AdjustCreditsModal({ account, onClose }: { account: CreditAccount; onClose: () => void }) {
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const adjustMutation = useAdjustCredits();
  const { addToast } = useUIStore();

  const handleSubmit = async () => {
    const num = parseFloat(amount);
    if (!num) return;
    try {
      await adjustMutation.mutateAsync({
        customerId: account.customer_id,
        amount: num,
        description,
      });
      addToast({ type: 'success', message: 'Creditos ajustados' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al ajustar creditos' });
    }
  };

  return (
    <Modal open onClose={onClose} title={`Ajustar creditos — ${account.customer_name}`}>
      <p className="mb-4 text-sm text-gray-500">
        Balance actual: <strong>${account.balance.toLocaleString()}</strong>
      </p>
      <div className="space-y-3">
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Monto</label>
          <p className="mb-1 text-xs text-gray-400">Positivo = agregar, negativo = quitar</p>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="Ej: 5000 o -2000"
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
          />
        </div>
        <Input
          label="Motivo"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Ej: Correccion, bonificacion..."
        />
      </div>
      <div className="mt-4 flex justify-end gap-3">
        <Button variant="ghost" onClick={onClose}>Cancelar</Button>
        <Button
          onClick={handleSubmit}
          loading={adjustMutation.isPending}
          disabled={!parseFloat(amount)}
        >
          {parseFloat(amount) > 0 ? (
            <><Plus className="mr-1.5 h-4 w-4" /> Agregar</>
          ) : parseFloat(amount) < 0 ? (
            <><Minus className="mr-1.5 h-4 w-4" /> Quitar</>
          ) : (
            'Ajustar'
          )}
        </Button>
      </div>
    </Modal>
  );
}
