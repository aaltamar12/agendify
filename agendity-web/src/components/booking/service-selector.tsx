'use client';

import { Clock, Tag, Zap } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Card } from '@/components/ui';
import { formatCurrency, formatDuration } from '@/lib/utils/format';
import { useBookingStore } from '@/lib/stores/booking-store';
import type { Service } from '@/lib/api/types';

interface ServiceSelectorProps {
  services: Service[];
  hasDynamicPricing?: boolean;
  /** Fraction of services with active dynamic pricing (0.0 to 1.0) */
  dynamicPricingCoverage?: number;
}

export function ServiceSelector({ services, hasDynamicPricing, dynamicPricingCoverage = 0 }: ServiceSelectorProps) {
  const showGeneralMessage = hasDynamicPricing && dynamicPricingCoverage >= 0.6;
  const showPerServiceMessage = hasDynamicPricing && !showGeneralMessage;
  const { selectedServices, toggleService } = useBookingStore();

  const activeServices = services.filter((s) => s.active);

  if (activeServices.length === 0) {
    return (
      <div className="py-12 text-center text-gray-500">
        No hay servicios disponibles en este momento.
      </div>
    );
  }

  // Group services by category
  const categories = new Map<string, Service[]>();
  activeServices.forEach((service) => {
    const cat = service.category || 'General';
    if (!categories.has(cat)) categories.set(cat, []);
    categories.get(cat)!.push(service);
  });

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-gray-900">
          Elige un servicio
        </h2>
        <p className="mt-1 text-sm text-gray-500">
          Selecciona el servicio que deseas reservar
        </p>
      </div>

      {/* General dynamic pricing message (≥60% of services) */}
      {showGeneralMessage && (
        <p className="flex items-center gap-1 text-sm text-amber-600">
          <Zap className="h-3.5 w-3.5" />
          El precio puede variar según el día
        </p>
      )}

      {Array.from(categories.entries()).map(([category, catServices]) => (
        <div key={category} className="space-y-3">
          {categories.size > 1 && (
            <h3 className="text-sm font-medium text-gray-500 uppercase tracking-wide">
              {category}
            </h3>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            {catServices.map((service) => {
              const isSelected = selectedServices.some((s) => s.id === service.id);

              return (
                <Card
                  key={service.id}
                  className={cn(
                    'cursor-pointer transition-all hover:shadow-md p-4',
                    isSelected
                      ? 'border-violet-600 ring-2 ring-violet-600/20'
                      : 'hover:border-gray-300',
                  )}
                  onClick={() => toggleService(service)}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0">
                      <h4 className="font-medium text-gray-900">
                        {service.name}
                      </h4>
                      {service.description && (
                        <p className="mt-1 text-sm text-gray-500 line-clamp-2">
                          {service.description}
                        </p>
                      )}
                    </div>
                    {isSelected && (
                      <div className="ml-2 h-5 w-5 shrink-0 rounded-full bg-violet-600 flex items-center justify-center">
                        <svg
                          className="h-3 w-3 text-white"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                          strokeWidth={3}
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            d="M5 13l4 4L19 7"
                          />
                        </svg>
                      </div>
                    )}
                  </div>
                  <div className="mt-3 flex items-center gap-4 text-sm">
                    <span className="flex items-center gap-1 text-violet-600 font-semibold">
                      <Tag className="h-3.5 w-3.5" />
                      {formatCurrency(service.price)}
                    </span>
                    <span className="flex items-center gap-1 text-gray-500">
                      <Clock className="h-3.5 w-3.5" />
                      {formatDuration(service.duration_minutes)}
                    </span>
                  </div>
                  {showPerServiceMessage && (
                    <p className="mt-2 flex items-center gap-1 text-xs text-amber-600">
                      <Zap className="h-3 w-3" />
                      El precio puede variar según el día
                    </p>
                  )}
                </Card>
              );
            })}
          </div>
        </div>
      ))}

      {/* Selection summary */}
      {selectedServices.length > 0 && (
        <div className="rounded-lg bg-violet-50 border border-violet-200 p-3">
          <p className="text-sm font-medium text-violet-900">
            {selectedServices.length} servicio{selectedServices.length > 1 ? 's' : ''} seleccionado{selectedServices.length > 1 ? 's' : ''}
          </p>
          <p className="text-xs text-violet-600">
            {formatCurrency(selectedServices.reduce((sum, s) => sum + Number(s.price), 0))} — {formatDuration(selectedServices.reduce((sum, s) => sum + s.duration_minutes, 0))}
          </p>
        </div>
      )}
    </div>
  );
}
