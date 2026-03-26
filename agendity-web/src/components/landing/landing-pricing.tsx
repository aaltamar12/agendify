'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Button } from '@/components/ui';
import { PlanCard } from '@/components/shared/plan-card';
import { getPlanSlug } from '@/lib/constants';
import type { Plan } from '@/lib/api/types';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

export function LandingPricing() {
  const [plans, setPlans] = useState<Plan[]>([]);

  useEffect(() => {
    fetch(`${API_URL}/api/v1/public/plans`)
      .then((r) => r.json())
      .then((res) => { if (res.data) setPlans(res.data); })
      .catch(() => {});
  }, []);

  if (plans.length === 0) return null;

  return (
    <section id="precios" className="px-6 py-20">
      <div className="mx-auto max-w-5xl">
        <h2 className="mb-4 text-center text-3xl font-bold text-gray-900">
          Planes simples, sin sorpresas
        </h2>
        <p className="mx-auto mb-12 max-w-2xl text-center text-gray-500">
          25 días gratis con acceso completo al Plan Inteligente. Sin tarjeta de crédito.
        </p>

        <div className="grid gap-6 sm:grid-cols-3">
          {plans.map((plan) => {
            const slug = getPlanSlug(plan.name ?? '');
            const isPrimary = slug === 'profesional' || slug === 'inteligente';
            return (
              <PlanCard key={plan.id} plan={plan}>
                <Link href="/register" className="mt-6 block">
                  <Button variant={isPrimary ? 'primary' : 'outline'} fullWidth>
                    Empezar gratis
                  </Button>
                </Link>
              </PlanCard>
            );
          })}
        </div>
      </div>
    </section>
  );
}
