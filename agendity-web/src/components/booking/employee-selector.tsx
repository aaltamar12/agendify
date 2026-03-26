'use client';

import { Users, Star } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Card, Avatar } from '@/components/ui';
import { StarRating } from '@/components/shared/star-rating';
import { useBookingStore } from '@/lib/stores/booking-store';
import type { Employee } from '@/lib/api/types';

interface EmployeeSelectorProps {
  employees: Employee[];
}

export function EmployeeSelector({ employees }: EmployeeSelectorProps) {
  const { selectedServices, selectedEmployee, setEmployee } = useBookingStore();

  // Filter employees that can perform ALL selected services
  const available = employees.filter((e) => {
    if (!e.active) return false;
    if (selectedServices.length === 0) return true;
    const serviceIds = (e as any).service_ids as number[] | undefined;
    if (!serviceIds) return true;
    return selectedServices.every((s) => serviceIds.includes(s.id));
  });

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-gray-900">
          Elige un profesional
        </h2>
        <p className="mt-1 text-sm text-gray-500">
          Selecciona quién te atenderá
          {selectedServices.length > 0 ? ` para ${selectedServices.map(s => s.name).join(' + ')}` : ''}
        </p>
      </div>

      {available.length === 0 && selectedServices.length > 1 && (
        <div className="rounded-lg bg-amber-50 border border-amber-200 p-4 text-center">
          <p className="text-sm font-medium text-amber-800">
            No hay un profesional que pueda hacer todos estos servicios juntos.
          </p>
          <p className="mt-1 text-xs text-amber-600">
            Te recomendamos reservar cada servicio por separado.
          </p>
        </div>
      )}

      <div className="grid gap-3 sm:grid-cols-2">
        {/* "Any available" option */}
        <Card
          className={cn(
            'cursor-pointer transition-all hover:shadow-md p-4',
            selectedEmployee === null
              ? 'border-violet-600 ring-2 ring-violet-600/20'
              : 'hover:border-gray-300',
          )}
          onClick={() => setEmployee(null)}
        >
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-violet-100">
              <Users className="h-5 w-5 text-violet-600" />
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="font-medium text-gray-900">
                Cualquier disponible
              </h4>
              <p className="text-sm text-gray-500">
                Se asignará automáticamente
              </p>
            </div>
            {selectedEmployee === null && (
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
        </Card>

        {/* Employee cards */}
        {available.map((employee) => {
          const isSelected = selectedEmployee?.id === employee.id;

          return (
            <Card
              key={employee.id}
              className={cn(
                'cursor-pointer transition-all hover:shadow-md p-4',
                isSelected
                  ? 'border-violet-600 ring-2 ring-violet-600/20'
                  : 'hover:border-gray-300',
              )}
              onClick={() => setEmployee(employee)}
            >
              <div className="flex items-center gap-3">
                <Avatar
                  src={employee.avatar_url}
                  name={employee.name}
                  size="md"
                />
                <div className="flex-1 min-w-0">
                  <h4 className="font-medium text-gray-900">
                    {employee.name}
                  </h4>
                  {(employee.rating_average ?? 0) > 0 && (
                    <div className="flex items-center gap-1 mt-0.5">
                      <StarRating rating={employee.rating_average ?? 0} size="sm" />
                      <span className="text-xs text-gray-500">
                        ({employee.total_reviews ?? 0})
                      </span>
                    </div>
                  )}
                  {employee.bio && (
                    <p className="text-sm text-gray-500 line-clamp-1">
                      {employee.bio}
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
            </Card>
          );
        })}
      </div>
    </div>
  );
}
