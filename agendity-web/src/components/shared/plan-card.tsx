import { Check, Sparkles } from 'lucide-react';
import { getPlanSlug, PLAN_FEATURES, PLAN_DESCRIPTIONS } from '@/lib/constants';
import { formatCurrency } from '@/lib/utils/format';
import type { Plan } from '@/lib/api/types';

interface PlanCardProps {
  plan: Plan;
  /** Show a selectable card with button */
  selectable?: boolean;
  selected?: boolean;
  onSelect?: () => void;
  /** Custom CTA slot rendered after features */
  children?: React.ReactNode;
}

export function PlanCard({ plan, selectable = false, selected = false, onSelect, children }: PlanCardProps) {
  const slug = getPlanSlug(plan.name ?? '');
  const isPopular = slug === 'profesional';
  const isInteligente = slug === 'inteligente';
  const features = (plan.features && plan.features.length > 0) ? plan.features : (PLAN_FEATURES[slug] ?? []);
  const description = plan.description ?? PLAN_DESCRIPTIONS[slug] ?? '';

  // Border: thick violet for Popular or selected, thin gray for others
  let borderClass = 'border border-gray-200';
  if (selectable && selected) {
    borderClass = 'border-2 border-violet-600 shadow-lg ring-1 ring-violet-600';
  } else if (isPopular) {
    borderClass = 'border-2 border-violet-600 shadow-lg';
  }

  return (
    <div
      className={`flex flex-col rounded-2xl p-6 transition-all ${borderClass} ${
        isInteligente ? 'bg-gradient-to-br from-violet-50 to-white' : 'bg-white'
      } ${selectable ? 'cursor-pointer' : ''}`}
      onClick={selectable ? onSelect : undefined}
    >
      {/* Header: name + badge/icon */}
      {(isPopular || isInteligente) ? (
        <div className="mb-2 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900">{plan.name}</h3>
          {isPopular && (
            <span className="rounded-full bg-violet-100 px-3 py-0.5 text-xs font-semibold text-violet-700">
              Popular
            </span>
          )}
          {isInteligente && <Sparkles className="h-5 w-5 text-violet-600" />}
        </div>
      ) : (
        <h3 className="text-lg font-semibold text-gray-900">{plan.name}</h3>
      )}
      {description && <p className="mt-1 text-sm text-gray-500">{description}</p>}

      {/* Price: USD primary, COP secondary */}
      <div className="mt-4">
        {plan.price_monthly_usd ? (
          <>
            <span className="text-4xl font-bold text-gray-900">${plan.price_monthly_usd}</span>
            <span className="text-sm text-gray-500"> USD/mes</span>
            <p className="mt-1 text-xs text-gray-400">~{formatCurrency(plan.price_monthly)} COP/mes</p>
          </>
        ) : (
          <>
            <span className="text-4xl font-bold text-gray-900">{formatCurrency(plan.price_monthly)}</span>
            <span className="text-sm text-gray-500"> /mes</span>
          </>
        )}
      </div>

      {/* Features */}
      {features.length > 0 && (
        <ul className="mt-6 flex-1 space-y-3">
          {features.map((f) => (
            <li key={f} className="flex items-start gap-2 text-sm text-gray-600">
              <Check className="mt-0.5 h-4 w-4 shrink-0 text-violet-600" />
              {f}
            </li>
          ))}
        </ul>
      )}

      {/* Selectable button (checkout) */}
      {selectable && (
        <button
          type="button"
          className={`mt-6 w-full rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
            selected
              ? 'bg-violet-600 text-white hover:bg-violet-700'
              : 'border border-gray-300 text-gray-700 hover:bg-gray-50'
          }`}
          onClick={(e) => { e.stopPropagation(); onSelect?.(); }}
        >
          {selected ? 'Seleccionado' : 'Seleccionar'}
        </button>
      )}

      {/* Custom CTA slot (landing, block screen) */}
      {children}

      {/* Inteligente upsell text */}
      {isInteligente && (
        <p className="mt-2 text-center text-xs font-medium text-violet-600">
          Solo ${(plan.price_monthly_usd ?? 0) - 22} USD más que el Profesional
        </p>
      )}
    </div>
  );
}
