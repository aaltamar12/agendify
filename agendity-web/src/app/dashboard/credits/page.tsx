'use client';

import { useState, useEffect, useRef } from 'react';
import { DollarSign, Plus, Minus, History, Search, UserPlus } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { Button, Card, Spinner, Modal, Input } from '@/components/ui';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import { useCreditsSummary, useCustomerCredits, useAdjustCredits, useBulkAdjustCredits } from '@/lib/hooks/use-credits';
import { useUIStore } from '@/lib/stores/ui-store';
import type { ApiResponse, Customer } from '@/lib/api/types';
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
  const [openCreditModal, setOpenCreditModal] = useState(false);

  const totalCredits = accounts?.reduce((sum, a) => sum + Number(a.balance), 0) ?? 0;

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Creditos de clientes</h1>
        <Button onClick={() => setOpenCreditModal(true)}>
          <UserPlus className="mr-2 h-4 w-4" />
          Abrir credito
        </Button>
      </div>

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
                  <th className="pb-3 pl-4 font-medium text-right">Balance</th>
                  <th className="pb-3 pl-4 font-medium">Acciones</th>
                </tr>
              </thead>
              <tbody>
                {accounts.map((account) => (
                  <tr key={account.id} className="border-b border-gray-100">
                    <td className="py-3 font-medium text-gray-900">{account.customer_name}</td>
                    <td className="py-3 text-gray-500">{account.customer_email || '—'}</td>
                    <td className="py-3 pl-4 text-right font-bold text-green-600">${Number(account.balance).toLocaleString()}</td>
                    <td className="py-3 pl-4">
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

      {/* Open credit modal */}
      {openCreditModal && (
        <OpenCreditModal
          onClose={() => setOpenCreditModal(false)}
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
        <p className="text-2xl font-bold text-green-600">${Number(account.balance).toLocaleString()}</p>
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

function OpenCreditModal({ onClose }: { onClose: () => void }) {
  const [mode, setMode] = useState<'select' | 'form'>('select');
  const [searchQuery, setSearchQuery] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [selectedCustomers, setSelectedCustomers] = useState<Customer[]>([]);
  const [applyToAll, setApplyToAll] = useState(false);
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const adjustMutation = useAdjustCredits();
  const bulkMutation = useBulkAdjustCredits();
  const { addToast } = useUIStore();
  const timeoutRef = useRef<ReturnType<typeof setTimeout>>(null);

  useEffect(() => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    timeoutRef.current = setTimeout(() => setDebouncedSearch(searchQuery), 300);
    return () => { if (timeoutRef.current) clearTimeout(timeoutRef.current); };
  }, [searchQuery]);

  const { data: customers, isLoading: searching } = useQuery({
    queryKey: ['customers-search-credits', debouncedSearch],
    queryFn: () => get<{ data: Customer[]; meta: unknown }>(ENDPOINTS.CUSTOMERS.list, { params: { search: debouncedSearch, per_page: 8 } }),
    enabled: debouncedSearch.length >= 2 && mode === 'select',
    select: (res) => res.data,
  });

  const addCustomer = (c: Customer) => {
    if (!selectedCustomers.find((s) => s.id === c.id)) {
      setSelectedCustomers([...selectedCustomers, c]);
    }
    setSearchQuery('');
    setDebouncedSearch('');
  };

  const removeCustomer = (id: number) => {
    setSelectedCustomers(selectedCustomers.filter((c) => c.id !== id));
  };

  const handleSubmit = async () => {
    const amt = parseFloat(amount);
    if (!amt || amt <= 0) return;

    try {
      if (applyToAll) {
        await bulkMutation.mutateAsync({ amount: amt, description: description || 'Credito masivo' });
        addToast({ type: 'success', message: 'Credito aplicado a todos los clientes' });
      } else if (selectedCustomers.length === 1) {
        await adjustMutation.mutateAsync({
          customerId: selectedCustomers[0].id,
          amount: amt,
          description: description || 'Credito inicial',
        });
        addToast({ type: 'success', message: `Credito abierto para ${selectedCustomers[0].name}` });
      } else {
        await bulkMutation.mutateAsync({
          customer_ids: selectedCustomers.map((c) => c.id),
          amount: amt,
          description: description || 'Credito masivo',
        });
        addToast({ type: 'success', message: `Credito aplicado a ${selectedCustomers.length} clientes` });
      }
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al abrir credito' });
    }
  };

  const isLoading = adjustMutation.isPending || bulkMutation.isPending;
  const canSubmit = (applyToAll || selectedCustomers.length > 0) && parseFloat(amount) > 0;

  return (
    <Modal open onClose={onClose} title="Abrir credito" size="lg">
      {mode === 'select' ? (
        <div className="space-y-4">
          {/* Apply to all toggle */}
          <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3">
            <div>
              <p className="text-sm font-medium text-gray-700">Aplicar a todos los clientes</p>
              <p className="text-xs text-gray-500">Dar credito a todos los clientes del negocio</p>
            </div>
            <label className="relative inline-flex cursor-pointer items-center">
              <input
                type="checkbox"
                className="peer sr-only"
                checked={applyToAll}
                onChange={(e) => { setApplyToAll(e.target.checked); if (e.target.checked) setSelectedCustomers([]); }}
              />
              <div className="h-6 w-11 rounded-full bg-gray-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:bg-white after:transition-all peer-checked:bg-violet-600 peer-checked:after:translate-x-full" />
            </label>
          </div>

          {!applyToAll && (
            <>
              {/* Search */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Buscar cliente..."
                  className="w-full rounded-lg border border-gray-300 py-2.5 pl-9 pr-3 text-sm focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
                  autoFocus
                />
              </div>

              {/* Search results */}
              {debouncedSearch.length >= 2 && (
                <div className="max-h-40 overflow-y-auto rounded-lg border border-gray-200">
                  {searching ? (
                    <div className="px-4 py-3 text-sm text-gray-500">Buscando...</div>
                  ) : customers && customers.length > 0 ? (
                    <ul>
                      {customers.map((c) => (
                        <li key={c.id}>
                          <button
                            type="button"
                            onClick={() => addCustomer(c)}
                            className="flex w-full cursor-pointer items-center gap-3 px-4 py-2 text-left hover:bg-gray-50"
                          >
                            <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-medium text-violet-600">
                              {c.name.charAt(0).toUpperCase()}
                            </div>
                            <div>
                              <p className="text-sm font-medium text-gray-900">{c.name}</p>
                              <p className="text-xs text-gray-500">{c.email || c.phone}</p>
                            </div>
                            {selectedCustomers.find((s) => s.id === c.id) && (
                              <span className="ml-auto text-xs text-green-600">Agregado</span>
                            )}
                          </button>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <div className="px-4 py-3 text-sm text-gray-500">No se encontraron clientes</div>
                  )}
                </div>
              )}

              {/* Selected customers chips */}
              {selectedCustomers.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {selectedCustomers.map((c) => (
                    <span key={c.id} className="inline-flex items-center gap-1 rounded-full bg-violet-100 px-3 py-1 text-xs font-medium text-violet-700">
                      {c.name}
                      <button type="button" onClick={() => removeCustomer(c.id)} className="cursor-pointer hover:text-violet-900">&times;</button>
                    </span>
                  ))}
                </div>
              )}
            </>
          )}

          <div className="flex justify-end">
            <Button
              onClick={() => setMode('form')}
              disabled={!applyToAll && selectedCustomers.length === 0}
            >
              Continuar
            </Button>
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          {/* Summary */}
          <div className="rounded-lg bg-violet-50 p-3">
            <p className="text-sm font-medium text-gray-900">
              {applyToAll
                ? 'Credito para todos los clientes'
                : selectedCustomers.length === 1
                  ? `Credito para ${selectedCustomers[0].name}`
                  : `Credito para ${selectedCustomers.length} clientes`}
            </p>
            {!applyToAll && selectedCustomers.length > 1 && (
              <p className="mt-1 text-xs text-gray-500">
                {selectedCustomers.map((c) => c.name).join(', ')}
              </p>
            )}
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Monto por cliente</label>
            <input
              type="number"
              min={1}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="Ej: 10000"
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
              autoFocus
            />
          </div>

          <Input
            label="Descripcion (opcional)"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Ej: Promocion de apertura, bonificacion..."
          />

          <div className="flex justify-between">
            <Button variant="ghost" onClick={() => setMode('select')}>Atras</Button>
            <Button onClick={handleSubmit} loading={isLoading} disabled={!canSubmit}>
              <Plus className="mr-1.5 h-4 w-4" />
              {applyToAll
                ? `Dar $${parseFloat(amount || '0').toLocaleString()} a todos`
                : `Dar $${parseFloat(amount || '0').toLocaleString()} a ${selectedCustomers.length} cliente${selectedCustomers.length !== 1 ? 's' : ''}`}
            </Button>
          </div>
        </div>
      )}
    </Modal>
  );
}
