import { useMemo } from 'react';
import { useCurrentBusiness } from './use-business';
import type { Plan, Subscription } from '@/lib/api/types';
import type { PlanSlug } from '@/lib/constants';
import { PLAN_DISPLAY, PLAN_FEATURE_LOCKS } from '@/lib/constants';

export interface SubscriptionInfo {
  subscription: Subscription | null;
  plan: Plan | null;
  planSlug: PlanSlug;
  planLabel: string;
  isTrialing: boolean;
  isLoading: boolean;
  daysUntilExpiry: number | null;
}

/**
 * Derives the current subscription and plan from the business API response.
 * Falls back to "trial" when the backend doesn't return subscription data.
 */
export function useCurrentSubscription(): SubscriptionInfo {
  const { data: business, isLoading } = useCurrentBusiness();

  return useMemo(() => {
    const subscription = business?.current_subscription ?? null;
    const plan = subscription?.plan ?? null;

    // Derive slug from plan name, with fallback
    const rawName = plan?.name?.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '') ?? '';
    let planSlug: PlanSlug = 'trial';

    if (rawName.includes('basico') || rawName.includes('básico')) {
      planSlug = 'basico';
    } else if (rawName.includes('inteligente')) {
      planSlug = 'inteligente';
    } else if (rawName.includes('profesional')) {
      planSlug = 'profesional';
    }

    // If subscription is active but no plan match, assume trial
    const isTrialing = subscription?.status === 'trialing' || !subscription;

    const planLabel = PLAN_DISPLAY[planSlug]?.label ?? 'Trial';

    // Calculate days until subscription or trial expires
    const endDate = subscription?.end_date || (isTrialing ? business?.trial_ends_at : null);
    let daysUntilExpiry: number | null = null;
    if (endDate) {
      const end = new Date(endDate.includes('T') ? endDate : endDate + 'T23:59:59');
      const now = new Date();
      daysUntilExpiry = Math.ceil((end.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    }

    return {
      subscription,
      plan,
      planSlug,
      planLabel,
      isTrialing,
      isLoading,
      daysUntilExpiry,
    };
  }, [business, isLoading]);
}

/**
 * Returns true if the given feature path is accessible under the current plan.
 */
export function useCanAccessFeature(featurePath: string): boolean {
  const { planSlug } = useCurrentSubscription();
  const lock = PLAN_FEATURE_LOCKS[featurePath];

  if (!lock) return true;
  return lock.requiredPlans.includes(planSlug);
}
