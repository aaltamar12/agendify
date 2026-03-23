'use client';

import { useState } from 'react';
import {
  Plus, Sparkles, TrendingUp, TrendingDown, Minus, Check, X,
  Calendar, ArrowRight, Trash2, Edit,
} from 'lucide-react';
import { Button, Card, Spinner, Modal, Input, Select, Badge } from '@/components/ui';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';
import {
  useDynamicPricings, useCreateDynamicPricing, useAcceptDynamicPricing,
  useRejectDynamicPricing, useDeleteDynamicPricing,
} from '@/lib/hooks/use-dynamic-pricing';
import { useServices } from '@/lib/hooks/use-services';
import { useBusinessHours } from '@/lib/hooks/use-business';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useUIStore } from '@/lib/stores/ui-store';
import { ADVANCED_REPORTS_PLANS, AI_FEATURES_PLANS } from '@/lib/constants';
import { formatCurrency } from '@/lib/utils/format';
import type { DynamicPricingPayload } from '@/lib/hooks/use-dynamic-pricing';
import type { DayOfWeek } from '@/lib/api/types';

const DAY_LABELS = ['Dom', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab'];

const MODE_LABELS: Record<string, string> = {
  fixed_mode: 'Fijo',
  progressive_asc: 'Progresivo ascendente',
  progressive_desc: 'Progresivo descendente',
};

export default function DynamicPricingPage() {
  const { planSlug } = useCurrentSubscription();
  const hasAccess = ADVANCED_REPORTS_PLANS.includes(planSlug);
  const hasAI = AI_FEATURES_PLANS.includes(planSlug);

  if (!hasAccess) {
    return (
      <div>
        <h1 className="mb-6 text-2xl font-bold text-gray-900">Tarifas dinamicas</h1>
        <UpgradeBanner feature="tarifas dinamicas" targetPlan="Profesional" />
      </div>
    );
  }

  return <DynamicPricingContent hasAI={hasAI} />;
}

function DynamicPricingContent({ hasAI }: { hasAI: boolean }) {
  const { data: pricings, isLoading } = useDynamicPricings();
  const acceptMutation = useAcceptDynamicPricing();
  const rejectMutation = useRejectDynamicPricing();
  const deleteMutation = useDeleteDynamicPricing();
  const { addToast } = useUIStore();
  const [createModal, setCreateModal] = useState(false);

  const suggestions = pricings?.filter((p) => p.status === 'suggested') ?? [];
  const activePricings = pricings?.filter((p) => p.status === 'active') ?? [];
  const pastPricings = pricings?.filter((p) => ['rejected', 'expired'].includes(p.status)) ?? [];

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Tarifas dinamicas</h1>
        <Button onClick={() => setCreateModal(true)}>
          <Plus className="mr-2 h-4 w-4" />
          Nueva tarifa
        </Button>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12"><Spinner size="lg" /></div>
      ) : (
        <div className="space-y-6">
          {/* AI Suggestions (only Plan Inteligente) */}
          {hasAI && suggestions.length > 0 && (
            <div>
              <h2 className="mb-3 flex items-center gap-2 text-lg font-semibold text-gray-900">
                <Sparkles className="h-5 w-5 text-amber-500" />
                Sugerencias inteligentes
              </h2>
              <div className="space-y-3">
                {suggestions.map((s) => (
                  <Card key={s.id} className="border-amber-200 bg-amber-50/50">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <Sparkles className="h-4 w-4 text-amber-500" />
                          <h3 className="font-semibold text-gray-900">{s.name}</h3>
                        </div>
                        <p className="mt-1 text-sm text-gray-600">{s.suggestion_reason}</p>
                        <div className="mt-2 flex flex-wrap gap-2 text-xs text-gray-500">
                          <span>{s.start_date} → {s.end_date}</span>
                          <span>·</span>
                          <span>{formatAdjustment(s)}</span>
                          {s.days_of_week?.length > 0 && (
                            <>
                              <span>·</span>
                              <span>{s.days_of_week.map((d) => DAY_LABELS[d]).join(', ')}</span>
                            </>
                          )}
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={async () => {
                            await rejectMutation.mutateAsync(s.id);
                            addToast({ type: 'info', message: 'Sugerencia rechazada' });
                          }}
                        >
                          <X className="mr-1 h-3.5 w-3.5" /> Rechazar
                        </Button>
                        <Button
                          size="sm"
                          onClick={async () => {
                            await acceptMutation.mutateAsync(s.id);
                            addToast({ type: 'success', message: 'Tarifa activada' });
                          }}
                        >
                          <Check className="mr-1 h-3.5 w-3.5" /> Aceptar
                        </Button>
                      </div>
                    </div>
                  </Card>
                ))}
              </div>
            </div>
          )}

          {hasAI && suggestions.length === 0 && (
            <Card className="border-amber-100 bg-amber-50/30">
              <div className="flex items-center gap-3 text-sm text-amber-700">
                <Sparkles className="h-5 w-5" />
                <p>No hay sugerencias nuevas. El analisis se ejecuta el 1ro y 15 de cada mes.</p>
              </div>
            </Card>
          )}

          {/* Active pricings */}
          <div>
            <h2 className="mb-3 text-lg font-semibold text-gray-900">Tarifas activas</h2>
            {activePricings.length === 0 ? (
              <Card>
                <p className="py-4 text-center text-sm text-gray-500">No hay tarifas activas.</p>
              </Card>
            ) : (
              <div className="space-y-3">
                {activePricings.map((p) => (
                  <Card key={p.id}>
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-semibold text-gray-900">{p.name}</h3>
                          {p.suggested_by === 'system' && <Sparkles className="h-3.5 w-3.5 text-amber-500" />}
                          {p.service_name && (
                            <span className="rounded-full bg-violet-100 px-2 py-0.5 text-xs text-violet-700">
                              {p.service_name}
                            </span>
                          )}
                        </div>
                        <div className="mt-1 flex flex-wrap gap-2 text-xs text-gray-500">
                          <span>{p.start_date} → {p.end_date}</span>
                          <span>·</span>
                          <span>{formatAdjustment(p)}</span>
                          {p.days_of_week?.length > 0 && (
                            <>
                              <span>·</span>
                              <span>Solo: {p.days_of_week.map((d) => DAY_LABELS[d]).join(', ')}</span>
                            </>
                          )}
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={async () => {
                          await deleteMutation.mutateAsync(p.id);
                          addToast({ type: 'info', message: 'Tarifa eliminada' });
                        }}
                        className="cursor-pointer text-gray-400 hover:text-red-600"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </Card>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {createModal && <CreatePricingModal onClose={() => setCreateModal(false)} />}
    </div>
  );
}

function formatAdjustment(p: { adjustment_mode: string; price_adjustment_type: string; adjustment_value: number | null; adjustment_start_value: number | null; adjustment_end_value: number | null }) {
  const suffix = p.price_adjustment_type === 'percentage' ? '%' : ' COP';
  if (p.adjustment_mode === 'fixed_mode') {
    const v = p.adjustment_value ?? 0;
    return `${v >= 0 ? '+' : ''}${v}${suffix}`;
  }
  const from = p.adjustment_start_value ?? 0;
  const to = p.adjustment_end_value ?? 0;
  return `${from >= 0 ? '+' : ''}${from}${suffix} → ${to >= 0 ? '+' : ''}${to}${suffix}`;
}

function CreatePricingModal({ onClose }: { onClose: () => void }) {
  const createMutation = useCreateDynamicPricing();
  const { data: services } = useServices();
  const { data: businessHours } = useBusinessHours();
  const { addToast } = useUIStore();

  // Days the business is open (not closed)
  const openDays = (businessHours || [])
    .filter((h) => !h.closed)
    .map((h) => h.day_of_week);

  const [form, setForm] = useState<DynamicPricingPayload>({
    name: '',
    service_id: null,
    start_date: '',
    end_date: '',
    price_adjustment_type: 'percentage',
    adjustment_mode: 'fixed_mode',
    adjustment_value: 0,
    adjustment_start_value: 0,
    adjustment_end_value: 0,
    days_of_week: [],
  });

  const update = (field: string, value: unknown) => setForm((f) => ({ ...f, [field]: value }));

  const toggleDay = (day: number) => {
    const days = form.days_of_week || [];
    update('days_of_week', days.includes(day) ? days.filter((d) => d !== day) : [...days, day]);
  };

  const handleSubmit = async () => {
    try {
      await createMutation.mutateAsync(form);
      addToast({ type: 'success', message: 'Tarifa creada' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al crear tarifa' });
    }
  };

  const isProgressive = form.adjustment_mode !== 'fixed_mode';
  const suffix = form.price_adjustment_type === 'percentage' ? '%' : ' COP';

  return (
    <Modal open onClose={onClose} title="Nueva tarifa dinamica" size="lg">
      <div className="space-y-4">
        <Input
          label="Nombre"
          value={form.name}
          onChange={(e) => update('name', e.target.value)}
          placeholder="Ej: Temporada navidena, Premium fin de semana"
        />

        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Servicio</label>
          <select
            value={form.service_id ?? ''}
            onChange={(e) => update('service_id', e.target.value ? Number(e.target.value) : null)}
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
          >
            <option value="">Todos los servicios</option>
            {services?.map((s) => (
              <option key={s.id} value={s.id}>{s.name}</option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Fecha inicio"
            type="date"
            value={form.start_date}
            onChange={(e) => update('start_date', e.target.value)}
          />
          <Input
            label="Fecha fin"
            type="date"
            value={form.end_date}
            onChange={(e) => update('end_date', e.target.value)}
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Tipo de ajuste</label>
            <select
              value={form.price_adjustment_type}
              onChange={(e) => update('price_adjustment_type', e.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
            >
              <option value="percentage">Porcentaje (%)</option>
              <option value="fixed">Monto fijo (COP)</option>
            </select>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Modo</label>
            <select
              value={form.adjustment_mode}
              onChange={(e) => update('adjustment_mode', e.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
            >
              <option value="fixed_mode">Fijo (mismo valor todo el periodo)</option>
              <option value="progressive_asc">Progresivo ascendente</option>
              <option value="progressive_desc">Progresivo descendente</option>
            </select>
          </div>
        </div>

        {!isProgressive ? (
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Valor del ajuste ({suffix.trim()})
            </label>
            <p className="mb-1 text-xs text-gray-400">Positivo = incremento, negativo = descuento</p>
            <input
              type="number"
              value={form.adjustment_value ?? ''}
              onChange={(e) => update('adjustment_value', parseFloat(e.target.value) || 0)}
              placeholder={`Ej: 20 = +20${suffix} o -10 = -10${suffix}`}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
            />
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">Valor inicial ({suffix.trim()})</label>
              <input
                type="number"
                value={form.adjustment_start_value ?? ''}
                onChange={(e) => update('adjustment_start_value', parseFloat(e.target.value) || 0)}
                placeholder={`Ej: 5`}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">Valor final ({suffix.trim()})</label>
              <input
                type="number"
                value={form.adjustment_end_value ?? ''}
                onChange={(e) => update('adjustment_end_value', parseFloat(e.target.value) || 0)}
                placeholder={`Ej: 25`}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
              />
            </div>
          </div>
        )}

        {/* Preview */}
        {form.adjustment_value !== 0 || form.adjustment_start_value !== 0 ? (
          <div className="rounded-lg bg-gray-50 p-3 text-sm">
            <p className="font-medium text-gray-700">Vista previa (servicio de $50,000):</p>
            {!isProgressive ? (
              <p className="text-gray-600">
                Precio ajustado: <strong>
                  {form.price_adjustment_type === 'percentage'
                    ? formatCurrency(50000 + 50000 * (form.adjustment_value || 0) / 100)
                    : formatCurrency(50000 + (form.adjustment_value || 0))
                  }
                </strong>
                {' '}({(form.adjustment_value || 0) >= 0 ? '+' : ''}{form.adjustment_value}{suffix})
              </p>
            ) : (
              <p className="text-gray-600">
                Dia 1: {form.price_adjustment_type === 'percentage'
                  ? formatCurrency(50000 + 50000 * (form.adjustment_start_value || 0) / 100)
                  : formatCurrency(50000 + (form.adjustment_start_value || 0))
                }
                {' → '}Ultimo dia: {form.price_adjustment_type === 'percentage'
                  ? formatCurrency(50000 + 50000 * (form.adjustment_end_value || 0) / 100)
                  : formatCurrency(50000 + (form.adjustment_end_value || 0))
                }
              </p>
            )}
          </div>
        ) : null}

        {/* Days of week filter */}
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-700">
            Dias de la semana (opcional)
          </label>
          <p className="mb-2 text-xs text-gray-400">Vacio = todos los dias laborales. Dias cerrados deshabilitados.</p>
          <div className="flex gap-1.5">
            {DAY_LABELS.map((label, i) => {
              const isClosed = !openDays.includes(i as DayOfWeek);
              return (
              <button
                key={i}
                type="button"
                disabled={isClosed}
                onClick={() => toggleDay(i)}
                className={`rounded-lg px-3 py-1.5 text-xs font-medium transition-colors ${
                  isClosed
                    ? 'cursor-not-allowed bg-gray-50 text-gray-300 line-through'
                    : (form.days_of_week || []).includes(i)
                      ? 'cursor-pointer bg-violet-600 text-white'
                      : 'cursor-pointer bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {label}
              </button>
              );
            })}
          </div>
        </div>

        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <Button variant="ghost" onClick={onClose}>Cancelar</Button>
          <Button
            onClick={handleSubmit}
            loading={createMutation.isPending}
            disabled={!form.name || !form.start_date || !form.end_date}
          >
            Crear tarifa
          </Button>
        </div>
      </div>
    </Modal>
  );
}
