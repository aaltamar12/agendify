'use client';

import { useEffect } from 'react';
import { ArrowLeft, ArrowRight } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Button } from '@/components/ui';
import { useBookingStore } from '@/lib/stores/booking-store';
import { usePriceCalendar } from '@/lib/hooks/use-public';
import { getNextDays } from '@/lib/utils/date';
import { ServiceSelector } from './service-selector';
import { EmployeeSelector } from './employee-selector';
import { DateTimePicker } from './date-time-picker';
import { CustomerForm } from './customer-form';
import { BookingConfirmation } from './booking-confirmation';
import type { Business, Service, Employee } from '@/lib/api/types';

interface BookingFlowProps {
  slug: string;
  business: Business;
  services: Service[];
  employees: Employee[];
  onClose?: () => void;
}

const STEP_LABELS = [
  'Servicio',
  'Profesional',
  'Fecha y hora',
  'Tus datos',
  'Confirmar',
];

export function BookingFlow({
  slug,
  business,
  services,
  employees,
  onClose,
}: BookingFlowProps) {
  const {
    currentStep,
    prevStep,
    nextStep,
    reset,
    selectedServices,
    selectedEmployee,
    selectedDate,
    selectedTime,
  } = useBookingStore();

  // Check if business has any active dynamic pricings using first service
  const firstService = services.find((s) => s.active);
  const days = getNextDays(14);
  const { data: priceCalendarCheck } = usePriceCalendar(
    slug,
    firstService?.id ?? 0,
    days[0],
    14,
  );
  const hasDynamicPricing = (priceCalendarCheck ?? []).some(
    (d) => d.has_dynamic_pricing,
  );

  // Reset store when component unmounts
  useEffect(() => {
    return () => {
      reset();
    };
  }, [reset]);

  const canGoBack = currentStep > 1;

  // For step 4, the "Next" is handled by the form submit
  const showNextButton = false; // Navigation is auto-advance via store

  return (
    <div className="space-y-6">
      {/* Progress indicator */}
      <div className="space-y-2">
        <div className="flex items-center justify-between text-xs text-gray-500">
          <span>
            Paso {currentStep} de {STEP_LABELS.length}
          </span>
          <span>{STEP_LABELS[currentStep - 1]}</span>
        </div>
        <div className="flex gap-1.5">
          {STEP_LABELS.map((_, idx) => (
            <div
              key={idx}
              className={cn(
                'h-1.5 flex-1 rounded-full transition-colors',
                idx < currentStep ? 'bg-violet-600' : 'bg-gray-200',
              )}
            />
          ))}
        </div>
      </div>

      {/* Step content */}
      <div className="min-h-[300px]">
        {currentStep === 1 && <ServiceSelector services={services} hasDynamicPricing={hasDynamicPricing} dynamicPricingCoverage={business.dynamic_pricing_coverage ?? 0} />}
        {currentStep === 2 && <EmployeeSelector employees={employees} />}
        {currentStep === 3 && <DateTimePicker slug={slug} />}
        {currentStep === 4 && <CustomerForm slug={slug} />}
        {currentStep === 5 && (
          <BookingConfirmation slug={slug} business={business} />
        )}
      </div>

      {/* Navigation */}
      {currentStep < 5 && (
        <div className="flex items-center justify-between border-t border-gray-100 pt-4">
          <div>
            {canGoBack ? (
              <Button variant="ghost" size="sm" onClick={prevStep}>
                <ArrowLeft className="h-4 w-4" />
                Atrás
              </Button>
            ) : onClose ? (
              <Button variant="ghost" size="sm" onClick={onClose}>
                Cancelar
              </Button>
            ) : null}
          </div>

          {/* Next button — different per step */}
          {currentStep === 1 && (
            <Button
              size="sm"
              disabled={selectedServices.length === 0}
              onClick={nextStep}
            >
              Siguiente
              <ArrowRight className="ml-1 h-4 w-4" />
            </Button>
          )}
          {currentStep === 2 && (
            <Button size="sm" onClick={nextStep}>
              Siguiente
              <ArrowRight className="ml-1 h-4 w-4" />
            </Button>
          )}
          {currentStep === 3 && (
            <Button
              size="sm"
              disabled={!selectedDate || !selectedTime}
              onClick={nextStep}
            >
              Siguiente
              <ArrowRight className="ml-1 h-4 w-4" />
            </Button>
          )}
          {/* Step 4 navigation is handled internally by CustomerForm */}
        </div>
      )}
    </div>
  );
}
