'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { CheckCircle2, Circle, ChevronDown, ChevronUp, Play, X } from 'lucide-react';
import { useOnboardingProgress } from '@/lib/hooks/use-onboarding';

const MINIMIZED_KEY = 'onboarding_minimized';

// YouTube video IDs for each onboarding step
// Replace these with the actual YouTube video IDs after uploading
const STEP_VIDEOS: Record<string, string> = {
  profile: 'M-JyAQWf7E4',
  hours: 'lxc2np-3NQw',
  services: 'cxPXZnu0CAw',
  employees: 'AGVvXPppGtU',
  employee_services: 'z4hEG5ylr2I',
  payment_methods: 'QLKZx7uQCvg',
};

export function OnboardingChecklist() {
  const { data, isLoading } = useOnboardingProgress();
  const [minimized, setMinimized] = useState(false);
  const [videoKey, setVideoKey] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setMinimized(localStorage.getItem(MINIMIZED_KEY) === 'true');
    }
  }, []);

  if (isLoading || !data || !data.steps) return null;
  if (data.all_complete) return null;

  const progressPercent = Math.round((data.completed / data.total) * 100);

  function toggleMinimize() {
    const next = !minimized;
    setMinimized(next);
    if (typeof window !== 'undefined') {
      localStorage.setItem(MINIMIZED_KEY, String(next));
    }
  }

  // Minimized: compact bar with progress
  if (minimized) {
    return (
      <div
        className="mb-4 cursor-pointer rounded-xl border border-violet-200 bg-white px-5 py-3 shadow-sm transition-colors hover:bg-violet-50"
        onClick={toggleMinimize}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-sm font-semibold text-gray-900">
              Configura tu negocio
            </span>
            <span className="text-xs text-gray-500">
              {data.completed}/{data.total}
            </span>
          </div>
          <ChevronDown className="h-4 w-4 text-gray-400" />
        </div>
        <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-gray-100">
          <div
            className="h-full rounded-full bg-violet-600 transition-all duration-500"
            style={{ width: `${progressPercent}%` }}
          />
        </div>
      </div>
    );
  }

  // Expanded: full checklist
  return (
    <div className="mb-6 rounded-xl border border-violet-200 bg-white p-6 shadow-sm">
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
          onClick={toggleMinimize}
          className="cursor-pointer rounded-lg p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors"
          aria-label="Minimizar"
        >
          <ChevronUp className="h-4 w-4" />
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
            <div className="flex items-center gap-3 rounded-lg px-2 py-1.5 text-sm transition-colors hover:bg-gray-50">
              <Link
                href={step.link}
                className="flex flex-1 items-center gap-3"
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
              {STEP_VIDEOS[step.key] && (
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    setVideoKey(step.key);
                  }}
                  className="flex cursor-pointer items-center gap-1 rounded-md px-2 py-1 text-xs font-medium text-violet-600 transition-colors hover:bg-violet-50"
                >
                  <Play className="h-3 w-3" />
                  Ver video
                </button>
              )}
            </div>
          </li>
        ))}
      </ul>

      {/* Video modal */}
      {videoKey && STEP_VIDEOS[videoKey] && (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60"
          onClick={() => setVideoKey(null)}
        >
          <div
            className="relative w-full max-w-3xl mx-4"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setVideoKey(null)}
              className="absolute -top-10 right-0 rounded-lg p-1 text-white/80 transition-colors hover:text-white"
            >
              <X className="h-6 w-6" />
            </button>
            <div className="aspect-video w-full overflow-hidden rounded-xl bg-black shadow-2xl">
              <iframe
                src={`https://www.youtube.com/embed/${STEP_VIDEOS[videoKey]}?autoplay=1&rel=0`}
                title="Tutorial"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
                className="h-full w-full"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
