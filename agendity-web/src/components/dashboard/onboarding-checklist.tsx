'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { CheckCircle2, Circle, X } from 'lucide-react';
import { useOnboardingProgress } from '@/lib/hooks/use-onboarding';

const DISMISS_KEY = 'onboarding_dismissed';

export function OnboardingChecklist() {
  const { data, isLoading } = useOnboardingProgress();
  const [dismissed, setDismissed] = useState(false);

  // Load dismissed state from localStorage on mount
  useEffect(() => {
    if (typeof window !== 'undefined') {
      setDismissed(localStorage.getItem(DISMISS_KEY) === 'true');
    }
  }, []);

  // Re-show if there are incomplete steps and user revisits
  useEffect(() => {
    if (data && !data.all_complete && dismissed) {
      // If there are still incomplete steps, re-appear
      setDismissed(false);
      localStorage.removeItem(DISMISS_KEY);
    }
  }, [data, dismissed]);

  if (isLoading || !data) return null;
  if (data.all_complete) return null;
  if (dismissed) return null;

  const progressPercent = Math.round((data.completed / data.total) * 100);

  function handleDismiss() {
    setDismissed(true);
    if (typeof window !== 'undefined') {
      localStorage.setItem(DISMISS_KEY, 'true');
    }
  }

  return (
    <div className="mx-4 mt-4 rounded-xl border border-violet-200 bg-white p-5 shadow-sm">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h3 className="text-base font-semibold text-gray-900">
            Configura tu negocio
          </h3>
          <p className="mt-0.5 text-sm text-gray-500">
            {data.completed} de {data.total} completados
          </p>
        </div>
        <button
          onClick={handleDismiss}
          className="cursor-pointer rounded-lg p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors"
          aria-label="Cerrar"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      {/* Progress bar */}
      <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-gray-100">
        <div
          className="h-full rounded-full bg-violet-600 transition-all duration-500"
          style={{ width: `${progressPercent}%` }}
        />
      </div>

      {/* Steps */}
      <ul className="mt-4 space-y-2">
        {data.steps.map((step) => (
          <li key={step.key}>
            <Link
              href={step.link}
              className="flex items-center gap-3 rounded-lg px-2 py-1.5 text-sm transition-colors hover:bg-gray-50"
            >
              {step.completed ? (
                <CheckCircle2 className="h-5 w-5 flex-shrink-0 text-violet-600" />
              ) : (
                <Circle className="h-5 w-5 flex-shrink-0 text-gray-300" />
              )}
              <span
                className={
                  step.completed
                    ? 'text-gray-400 line-through'
                    : 'text-gray-700'
                }
              >
                {step.label}
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
