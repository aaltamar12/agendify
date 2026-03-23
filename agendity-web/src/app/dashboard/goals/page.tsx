'use client';

import { useState } from 'react';
import { Target, Plus, Trash2, TrendingUp, AlertTriangle, CheckCircle, Sparkles } from 'lucide-react';
import { Button, Card, Spinner, Modal, Input } from '@/components/ui';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';
import { useGoals, useGoalProgress, useCreateGoal, useDeleteGoal } from '@/lib/hooks/use-goals';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useUIStore } from '@/lib/stores/ui-store';
import { AI_FEATURES_PLANS } from '@/lib/constants';
import type { GoalProgress } from '@/lib/hooks/use-goals';

const GOAL_TYPES = [
  { value: 'monthly_sales', label: 'Meta mensual de ventas', description: 'Cuanto quieres vender este mes' },
  { value: 'break_even', label: 'Punto de equilibrio', description: 'Ingresos minimos para cubrir costos fijos' },
  { value: 'daily_average', label: 'Promedio diario', description: 'Ingreso diario objetivo' },
  { value: 'custom', label: 'Meta personalizada', description: 'Define tu propia meta' },
];

const STATUS_CONFIG: Record<string, { color: string; bg: string; icon: typeof CheckCircle }> = {
  achieved: { color: 'text-green-700', bg: 'bg-green-100', icon: CheckCircle },
  on_track: { color: 'text-blue-700', bg: 'bg-blue-100', icon: TrendingUp },
  behind: { color: 'text-orange-700', bg: 'bg-orange-100', icon: AlertTriangle },
  at_risk: { color: 'text-red-700', bg: 'bg-red-100', icon: AlertTriangle },
};

export default function GoalsPage() {
  const { planSlug } = useCurrentSubscription();
  if (!AI_FEATURES_PLANS.includes(planSlug)) {
    return (
      <div>
        <h1 className="mb-6 text-2xl font-bold text-gray-900">Metas financieras</h1>
        <UpgradeBanner feature="metas financieras" targetPlan="Inteligente" />
      </div>
    );
  }
  return <GoalsContent />;
}

function GoalsContent() {
  const { data: progress, isLoading } = useGoalProgress();
  const deleteMutation = useDeleteGoal();
  const { addToast } = useUIStore();
  const [createModal, setCreateModal] = useState(false);

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900">Metas financieras</h1>
          <Sparkles className="h-5 w-5 text-amber-500" />
        </div>
        <Button onClick={() => setCreateModal(true)}>
          <Plus className="mr-2 h-4 w-4" />
          Nueva meta
        </Button>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12"><Spinner size="lg" /></div>
      ) : !progress || progress.length === 0 ? (
        <Card>
          <div className="py-8 text-center">
            <Target className="mx-auto mb-3 h-12 w-12 text-gray-300" />
            <p className="text-gray-500">No tienes metas configuradas.</p>
            <p className="mt-1 text-sm text-gray-400">Crea metas para ver tu progreso financiero.</p>
            <Button className="mt-4" onClick={() => setCreateModal(true)}>
              <Plus className="mr-2 h-4 w-4" /> Crear primera meta
            </Button>
          </div>
        </Card>
      ) : (
        <div className="space-y-4">
          {progress.map((goal) => (
            <GoalCard
              key={goal.id}
              goal={goal}
              onDelete={async () => {
                await deleteMutation.mutateAsync(goal.id);
                addToast({ type: 'success', message: 'Meta eliminada' });
              }}
            />
          ))}
        </div>
      )}

      {createModal && <CreateGoalModal onClose={() => setCreateModal(false)} />}
    </div>
  );
}

function GoalCard({ goal, onDelete }: { goal: GoalProgress; onDelete: () => void }) {
  const config = STATUS_CONFIG[goal.status] || STATUS_CONFIG.behind;
  const Icon = config.icon;

  return (
    <Card>
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-gray-900">{goal.name}</h3>
            <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${config.bg} ${config.color}`}>
              <Icon className="h-3 w-3" />
              {goal.status === 'achieved' ? 'Cumplida' : goal.status === 'on_track' ? 'En camino' : goal.status === 'behind' ? 'Atrasado' : 'En riesgo'}
            </span>
          </div>

          {/* Progress bar */}
          <div className="mt-3">
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-500">${Number(goal.current_value).toLocaleString()}</span>
              <span className="font-medium text-gray-700">${Number(goal.target_value).toLocaleString()}</span>
            </div>
            <div className="mt-1 h-3 w-full overflow-hidden rounded-full bg-gray-200">
              <div
                className={`h-full rounded-full transition-all ${
                  goal.progress >= 100 ? 'bg-green-500' : goal.progress >= 70 ? 'bg-blue-500' : goal.progress >= 40 ? 'bg-orange-500' : 'bg-red-500'
                }`}
                style={{ width: `${Math.min(goal.progress, 100)}%` }}
              />
            </div>
            <p className="mt-1 text-xs text-gray-500">{goal.progress}% completado</p>
          </div>

          {/* Suggestion */}
          <div className="mt-3 rounded-lg bg-gray-50 p-3">
            <p className="text-sm text-gray-700">{goal.suggestion}</p>
          </div>
        </div>

        <button onClick={onDelete} className="ml-4 cursor-pointer text-gray-400 hover:text-red-500">
          <Trash2 className="h-4 w-4" />
        </button>
      </div>
    </Card>
  );
}

function CreateGoalModal({ onClose }: { onClose: () => void }) {
  const [goalType, setGoalType] = useState('monthly_sales');
  const [name, setName] = useState('');
  const [targetValue, setTargetValue] = useState('');
  const [fixedCosts, setFixedCosts] = useState('');
  const createMutation = useCreateGoal();
  const { addToast } = useUIStore();

  const handleSubmit = async () => {
    try {
      await createMutation.mutateAsync({
        goal_type: goalType,
        name: name || GOAL_TYPES.find((g) => g.value === goalType)?.label,
        target_value: parseFloat(targetValue),
        fixed_costs: goalType === 'break_even' ? parseFloat(fixedCosts) : undefined,
      });
      addToast({ type: 'success', message: 'Meta creada' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al crear meta' });
    }
  };

  return (
    <Modal open onClose={onClose} title="Nueva meta financiera">
      <div className="space-y-4">
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Tipo de meta</label>
          {GOAL_TYPES.map((type) => (
            <label
              key={type.value}
              className={`mt-2 flex cursor-pointer items-center gap-3 rounded-lg border p-3 transition-colors ${
                goalType === type.value ? 'border-violet-500 bg-violet-50' : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <input
                type="radio"
                name="goal_type"
                value={type.value}
                checked={goalType === type.value}
                onChange={(e) => setGoalType(e.target.value)}
                className="text-violet-600"
              />
              <div>
                <p className="text-sm font-medium text-gray-900">{type.label}</p>
                <p className="text-xs text-gray-500">{type.description}</p>
              </div>
            </label>
          ))}
        </div>

        <Input
          label="Nombre (opcional)"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Ej: Meta marzo, Punto equilibrio Q1"
        />

        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">
            {goalType === 'daily_average' ? 'Ingreso diario objetivo' : 'Valor objetivo ($)'}
          </label>
          <input
            type="number"
            min={1}
            value={targetValue}
            onChange={(e) => setTargetValue(e.target.value)}
            placeholder={goalType === 'daily_average' ? 'Ej: 200000' : 'Ej: 5000000'}
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
          />
        </div>

        {goalType === 'break_even' && (
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Costos fijos mensuales ($)</label>
            <input
              type="number"
              min={0}
              value={fixedCosts}
              onChange={(e) => setFixedCosts(e.target.value)}
              placeholder="Ej: arriendo + servicios + salarios = 3000000"
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
            />
            <p className="mt-1 text-xs text-gray-400">Arriendo, servicios, salarios fijos, etc.</p>
          </div>
        )}

        <div className="flex justify-end gap-3">
          <Button variant="ghost" onClick={onClose}>Cancelar</Button>
          <Button onClick={handleSubmit} loading={createMutation.isPending} disabled={!parseFloat(targetValue)}>
            Crear meta
          </Button>
        </div>
      </div>
    </Modal>
  );
}
