'use client';

import { useRef } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import dayjs from 'dayjs';
import { cn } from '@/lib/utils/cn';
import { Spinner } from '@/components/ui';
import { getNextDays, parseDate, formatTime } from '@/lib/utils/date';
import { useBookingStore } from '@/lib/stores/booking-store';
import { useAvailability } from '@/lib/hooks/use-public';

interface DateTimePickerProps {
  slug: string;
}

export function DateTimePicker({ slug }: DateTimePickerProps) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const {
    selectedService,
    selectedEmployee,
    selectedDate,
    selectedTime,
    setDateTime,
  } = useBookingStore();
  const setStep = useBookingStore((s) => s.setStep);

  const days = getNextDays(14);

  // Temporary local date state before confirming
  const currentDate = selectedDate || days[0];

  const { data: availability, isLoading: loadingSlots } = useAvailability(
    slug,
    {
      service_id: selectedService?.id ?? 0,
      employee_id: selectedEmployee?.id ?? null,
      date: currentDate,
    },
  );

  const slots = availability?.slots ?? [];

  function handleDateSelect(date: string) {
    // Update the store date but keep on step 3
    useBookingStore.setState({ selectedDate: date, selectedTime: null });
  }

  function handleTimeSelect(time: string) {
    setDateTime(currentDate, time);
  }

  function scrollDates(direction: 'left' | 'right') {
    if (!scrollRef.current) return;
    const amount = direction === 'left' ? -200 : 200;
    scrollRef.current.scrollBy({ left: amount, behavior: 'smooth' });
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-gray-900">
          Elige fecha y hora
        </h2>
        <p className="mt-1 text-sm text-gray-500">
          Selecciona el día y horario que prefieras
        </p>
      </div>

      {/* Date selector */}
      <div className="space-y-3">
        <h3 className="text-sm font-medium text-gray-700">Fecha</h3>
        <div className="relative">
          <button
            type="button"
            onClick={() => scrollDates('left')}
            className="absolute left-0 top-1/2 z-10 -translate-y-1/2 rounded-full bg-white p-1 shadow-md hover:bg-gray-50"
          >
            <ChevronLeft className="h-4 w-4 text-gray-600" />
          </button>

          <div
            ref={scrollRef}
            className="flex gap-2 overflow-x-auto px-8 py-1 scrollbar-hide"
          >
            {days.map((date) => {
              const d = parseDate(date);
              const isSelected = currentDate === date;
              const dayName = d.format('ddd');
              const dayNum = d.format('D');
              const monthName = d.format('MMM');

              return (
                <button
                  key={date}
                  type="button"
                  onClick={() => handleDateSelect(date)}
                  className={cn(
                    'flex shrink-0 flex-col items-center rounded-xl px-3 py-2 text-sm transition-all min-w-[60px]',
                    isSelected
                      ? 'bg-violet-600 text-white shadow-md'
                      : 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-200',
                  )}
                >
                  <span className="text-xs font-medium uppercase">
                    {dayName}
                  </span>
                  <span className="text-lg font-bold">{dayNum}</span>
                  <span className="text-xs">{monthName}</span>
                </button>
              );
            })}
          </div>

          <button
            type="button"
            onClick={() => scrollDates('right')}
            className="absolute right-0 top-1/2 z-10 -translate-y-1/2 rounded-full bg-white p-1 shadow-md hover:bg-gray-50"
          >
            <ChevronRight className="h-4 w-4 text-gray-600" />
          </button>
        </div>
      </div>

      {/* Time slots */}
      <div className="space-y-3">
        <h3 className="text-sm font-medium text-gray-700">Hora disponible</h3>

        {loadingSlots ? (
          <div className="flex items-center justify-center py-8">
            <Spinner size="md" />
          </div>
        ) : slots.length === 0 ? (
          <div className="rounded-lg bg-gray-50 px-4 py-8 text-center text-sm text-gray-500">
            No hay horarios disponibles para esta fecha. Prueba con otro día.
          </div>
        ) : (
          <div className="grid grid-cols-3 gap-2 sm:grid-cols-4 md:grid-cols-5">
            {slots.map((slot) => {
              const isSelected = selectedTime === slot && currentDate === selectedDate;

              return (
                <button
                  key={slot}
                  type="button"
                  onClick={() => handleTimeSelect(slot)}
                  className={cn(
                    'rounded-lg px-3 py-2.5 text-sm font-medium transition-all',
                    isSelected
                      ? 'bg-violet-600 text-white shadow-md'
                      : 'bg-white text-gray-700 hover:bg-violet-50 hover:text-violet-700 border border-gray-200',
                  )}
                >
                  {formatTime(slot)}
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
