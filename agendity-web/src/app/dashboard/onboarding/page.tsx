'use client';

import { useState } from 'react';
import { Card } from '@/components/ui';
import { cn } from '@/lib/utils/cn';
import { StepBusinessProfile } from '@/components/onboarding/step-business-profile';
import { StepBusinessHours } from '@/components/onboarding/step-business-hours';
import { StepServices } from '@/components/onboarding/step-services';
import { StepEmployees } from '@/components/onboarding/step-employees';
import { StepPaymentMethods } from '@/components/onboarding/step-payment-methods';
import { StepCancellationPolicy } from '@/components/onboarding/step-cancellation-policy';

const STEPS = [
  { number: 1, label: 'Perfil' },
  { number: 2, label: 'Horario' },
  { number: 3, label: 'Servicios' },
  { number: 4, label: 'Empleados' },
  { number: 5, label: 'Pagos' },
  { number: 6, label: 'Cancelación' },
];

export default function OnboardingPage() {
  const [currentStep, setCurrentStep] = useState(1);

  const goNext = () => setCurrentStep((s) => Math.min(s + 1, 6));
  const goBack = () => setCurrentStep((s) => Math.max(s - 1, 1));
  const goSkip = () => goNext();

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      <div className="mb-8 text-center">
        <h1 className="text-2xl font-bold text-gray-900">
          Configura tu negocio
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          Completa estos pasos para empezar a recibir citas.
        </p>
      </div>

      {/* Step indicators */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          {STEPS.map((step) => (
            <div key={step.number} className="flex flex-col items-center">
              <div
                className={cn(
                  'flex h-8 w-8 items-center justify-center rounded-full text-sm font-medium transition-colors',
                  currentStep === step.number
                    ? 'bg-violet-600 text-white'
                    : currentStep > step.number
                      ? 'bg-violet-100 text-violet-600'
                      : 'bg-gray-200 text-gray-500',
                )}
              >
                {currentStep > step.number ? (
                  <svg
                    className="h-4 w-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2.5}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                ) : (
                  step.number
                )}
              </div>
              <span
                className={cn(
                  'mt-1 text-xs',
                  currentStep === step.number
                    ? 'font-medium text-violet-600'
                    : 'text-gray-400',
                )}
              >
                {step.label}
              </span>
            </div>
          ))}
        </div>

        {/* Progress bar */}
        <div className="mt-4 h-1 w-full rounded-full bg-gray-200">
          <div
            className="h-1 rounded-full bg-violet-600 transition-all"
            style={{ width: `${((currentStep - 1) / 5) * 100}%` }}
          />
        </div>
      </div>

      {/* Step content */}
      <Card>
        {currentStep === 1 && <StepBusinessProfile onNext={goNext} />}
        {currentStep === 2 && (
          <StepBusinessHours onNext={goNext} onBack={goBack} onSkip={goSkip} />
        )}
        {currentStep === 3 && (
          <StepServices onNext={goNext} onBack={goBack} />
        )}
        {currentStep === 4 && (
          <StepEmployees onNext={goNext} onBack={goBack} />
        )}
        {currentStep === 5 && (
          <StepPaymentMethods
            onNext={goNext}
            onBack={goBack}
            onSkip={goSkip}
          />
        )}
        {currentStep === 6 && <StepCancellationPolicy onBack={goBack} />}
      </Card>
    </div>
  );
}
