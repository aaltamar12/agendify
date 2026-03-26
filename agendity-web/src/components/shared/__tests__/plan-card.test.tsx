import { describe, it, expect, afterEach } from 'vitest';
import { render, screen, cleanup } from '@testing-library/react';
import { PlanCard } from '../plan-card';
import type { Plan } from '@/lib/api/types';

afterEach(cleanup);

const basePlan: Plan = {
  id: 1,
  name: 'Básico',
  slug: 'basico',
  description: null,
  price_monthly: 49900,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
};

const profesionalPlan: Plan = {
  id: 2,
  name: 'Profesional',
  slug: 'profesional',
  description: 'Para negocios que quieren crecer',
  price_monthly: 89900,
  price_monthly_usd: 22,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
};

const inteligentePlan: Plan = {
  id: 3,
  name: 'Inteligente',
  slug: 'inteligente',
  description: null,
  price_monthly: 149900,
  price_monthly_usd: 35,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
};

describe('PlanCard', () => {
  it('renders the plan name', () => {
    render(<PlanCard plan={basePlan} />);
    expect(screen.getByText('Básico')).toBeInTheDocument();
  });

  it('renders the price for COP-only plan', () => {
    render(<PlanCard plan={basePlan} />);
    expect(screen.getByText('$49.900')).toBeInTheDocument();
    expect(screen.getByText(/\/mes/)).toBeInTheDocument();
  });

  it('renders USD price when available', () => {
    render(<PlanCard plan={profesionalPlan} />);
    expect(screen.getByText('$22')).toBeInTheDocument();
    expect(screen.getByText(/USD\/mes/)).toBeInTheDocument();
  });

  it('shows "Popular" badge for Profesional plan', () => {
    render(<PlanCard plan={profesionalPlan} />);
    expect(screen.getByText('Popular')).toBeInTheDocument();
  });

  it('does NOT show "Popular" badge for Básico plan', () => {
    render(<PlanCard plan={basePlan} />);
    expect(screen.queryByText('Popular')).not.toBeInTheDocument();
  });

  it('renders features from PLAN_FEATURES fallback', () => {
    render(<PlanCard plan={basePlan} />);
    expect(screen.getByText('Agenda y calendario')).toBeInTheDocument();
  });

  it('renders custom features from plan object when provided', () => {
    const planWithFeatures: Plan = {
      ...basePlan,
      features: ['Custom feature 1', 'Custom feature 2'],
    };
    render(<PlanCard plan={planWithFeatures} />);
    expect(screen.getByText('Custom feature 1')).toBeInTheDocument();
    expect(screen.getByText('Custom feature 2')).toBeInTheDocument();
  });

  it('renders description from plan object', () => {
    render(<PlanCard plan={profesionalPlan} />);
    expect(screen.getByText('Para negocios que quieren crecer')).toBeInTheDocument();
  });

  it('renders selectable button when selectable=true', () => {
    render(<PlanCard plan={basePlan} selectable />);
    expect(screen.getByRole('button', { name: 'Seleccionar' })).toBeInTheDocument();
  });

  it('renders "Seleccionado" when selected', () => {
    render(<PlanCard plan={basePlan} selectable selected />);
    expect(screen.getByRole('button', { name: 'Seleccionado' })).toBeInTheDocument();
  });

  it('renders children as custom CTA', () => {
    render(
      <PlanCard plan={basePlan}>
        <button>Custom CTA</button>
      </PlanCard>,
    );
    expect(screen.getByText('Custom CTA')).toBeInTheDocument();
  });
});
