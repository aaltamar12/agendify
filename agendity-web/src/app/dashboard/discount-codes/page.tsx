'use client';

import { useState } from 'react';
import { Tag, Plus, Trash2, ChevronLeft, ChevronRight } from 'lucide-react';
import { Card, Button, Skeleton, EmptyState } from '@/components/ui';
import { useDiscountCodes, useCreateDiscountCode, useDeleteDiscountCode } from '@/lib/hooks/use-discount-codes';
import { useCanAccessFeature } from '@/lib/hooks/use-subscription';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';
import { formatCurrency } from '@/lib/utils/format';

function DiscountCodeSkeleton() {
  return (
    <Card>
      <div className="flex items-center justify-between">
        <div className="space-y-2">
          <Skeleton className="h-5 w-32" />
          <Skeleton className="h-4 w-48" />
        </div>
        <Skeleton className="h-8 w-8 rounded" />
      </div>
    </Card>
  );
}

export default function DiscountCodesPage() {
  const [page, setPage] = useState(1);
  const [showForm, setShowForm] = useState(false);
  const { data: response, isLoading } = useDiscountCodes(page);
  const createMutation = useCreateDiscountCode();
  const deleteMutation = useDeleteDiscountCode();
  const canAccess = useCanAccessFeature('/dashboard/discount-codes');

  const codes = response?.data;
  const meta = response?.meta;

  // Form state
  const [formCode, setFormCode] = useState('');
  const [formType, setFormType] = useState<'percentage' | 'fixed'>('percentage');
  const [formValue, setFormValue] = useState('');
  const [formMaxUses, setFormMaxUses] = useState('');
  const [formValidUntil, setFormValidUntil] = useState('');

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    await createMutation.mutateAsync({
      code: formCode.trim().toUpperCase(),
      discount_type: formType,
      discount_value: parseFloat(formValue),
      max_uses: formMaxUses ? parseInt(formMaxUses) : null,
      valid_until: formValidUntil || null,
    });
    setFormCode('');
    setFormValue('');
    setFormMaxUses('');
    setFormValidUntil('');
    setShowForm(false);
  }

  async function handleDelete(id: number) {
    if (!confirm('¿Eliminar este código de descuento?')) return;
    await deleteMutation.mutateAsync(id);
  }

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('es-CO', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Códigos de descuento</h1>
          {meta && (
            <p className="mt-1 text-sm text-gray-500">
              {meta.total_count} código{meta.total_count !== 1 ? 's' : ''} en total
            </p>
          )}
        </div>
        <Button size="sm" onClick={() => setShowForm(!showForm)}>
          <Plus className="mr-1 h-4 w-4" />
          Nuevo código
        </Button>
      </div>

      {/* Upgrade banner for restricted plans */}
      {!canAccess && (
        <UpgradeBanner
          feature="códigos de descuento"
          targetPlan="Profesional"
          className="mb-6"
        />
      )}

      {/* Create form */}
      {showForm && (
        <Card className="mb-6">
          <form onSubmit={handleCreate} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Código
                </label>
                <input
                  type="text"
                  value={formCode}
                  onChange={(e) => setFormCode(e.target.value)}
                  placeholder="Ej: CUMPLE10"
                  required
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm uppercase focus:border-violet-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Tipo de descuento
                </label>
                <select
                  value={formType}
                  onChange={(e) => setFormType(e.target.value as 'percentage' | 'fixed')}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
                >
                  <option value="percentage">Porcentaje (%)</option>
                  <option value="fixed">Monto fijo ($)</option>
                </select>
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Valor ({formType === 'percentage' ? '%' : '$'})
                </label>
                <input
                  type="number"
                  value={formValue}
                  onChange={(e) => setFormValue(e.target.value)}
                  placeholder={formType === 'percentage' ? 'Ej: 10' : 'Ej: 5000'}
                  required
                  min={0}
                  max={formType === 'percentage' ? 100 : undefined}
                  step={formType === 'percentage' ? 1 : 100}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Usos máximos (opcional)
                </label>
                <input
                  type="number"
                  value={formMaxUses}
                  onChange={(e) => setFormMaxUses(e.target.value)}
                  placeholder="Ilimitado"
                  min={1}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Válido hasta (opcional)
                </label>
                <input
                  type="date"
                  value={formValidUntil}
                  onChange={(e) => setFormValidUntil(e.target.value)}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
                />
              </div>
            </div>
            <div className="flex gap-2">
              <Button type="submit" size="sm" loading={createMutation.isPending}>
                Crear código
              </Button>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setShowForm(false)}
              >
                Cancelar
              </Button>
            </div>
          </form>
        </Card>
      )}

      {/* Loading state */}
      {isLoading && (
        <div className="space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <DiscountCodeSkeleton key={i} />
          ))}
        </div>
      )}

      {/* Empty state */}
      {!isLoading && (!codes || codes.length === 0) && (
        <EmptyState
          icon={Tag}
          title="No hay códigos de descuento"
          description="Crea códigos de descuento para tus clientes. Se pueden usar durante el flujo de reserva."
        />
      )}

      {/* Code list */}
      {!isLoading && codes && codes.length > 0 && (
        <div className="space-y-3">
          {codes.map((dc) => (
            <Card key={dc.id}>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-violet-100">
                    <Tag className="h-5 w-5 text-violet-600" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="font-mono font-semibold text-gray-900">
                        {dc.code}
                      </p>
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                          dc.active
                            ? 'bg-green-100 text-green-700'
                            : 'bg-gray-100 text-gray-500'
                        }`}
                      >
                        {dc.active ? 'Activo' : 'Inactivo'}
                      </span>
                    </div>
                    <p className="text-sm text-gray-500">
                      {dc.discount_type === 'percentage'
                        ? `${dc.discount_value}% de descuento`
                        : `${formatCurrency(dc.discount_value)} de descuento`}
                      {' · '}
                      {dc.current_uses}/{dc.max_uses ?? '---'} usos
                      {dc.valid_until && (
                        <>
                          {' · '}
                          Hasta {formatDate(dc.valid_until)}
                        </>
                      )}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => handleDelete(dc.id)}
                  disabled={deleteMutation.isPending}
                  className="rounded-lg p-2 text-gray-400 hover:bg-red-50 hover:text-red-500 transition-colors"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Pagination */}
      {meta && meta.total_pages > 1 && (
        <div className="mt-6 flex items-center justify-between">
          <p className="text-sm text-gray-500">
            Página {meta.current_page} de {meta.total_pages}
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
            >
              <ChevronLeft className="h-4 w-4" />
              Anterior
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= meta.total_pages}
              onClick={() => setPage((p) => p + 1)}
            >
              Siguiente
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
