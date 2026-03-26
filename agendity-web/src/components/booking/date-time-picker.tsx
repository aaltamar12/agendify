'use client';

import { useRef, useEffect, useMemo } from 'react';
import { ChevronLeft, ChevronRight, Zap } from 'lucide-react';
import dayjs from 'dayjs';
import { cn } from '@/lib/utils/cn';
import { Spinner } from '@/components/ui';
import { getNextDays, parseDate, formatTime } from '@/lib/utils/date';
import { formatCurrency } from '@/lib/utils/format';
import { useBookingStore } from '@/lib/stores/booking-store';
import { useAvailability, usePriceCalendar, usePricePreview } from '@/lib/hooks/use-public';

interface DateTimePickerProps {
  slug: string;
}

export function DateTimePicker({ slug }: DateTimePickerProps) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const {
    selectedService,
    selectedServices,
    selectedEmployee,
    selectedDate,
    selectedTime,
    setDateTime,
    setDynamicPricing,
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

  // Fetch price calendar for next 14 days
  const { data: priceCalendar } = usePriceCalendar(
    slug,
    selectedService?.id ?? 0,
    days[0],
    14,
  );

  // Fetch price preview for the currently selected date
  const { data: pricePreview } = usePricePreview(
    slug,
    selectedService?.id ?? 0,
    currentDate,
  );

  // Sync price preview data to the store when it changes
  useEffect(() => {
    if (pricePreview) {
      setDynamicPricing({
        base_price: pricePreview.base_price,
        adjusted_price: pricePreview.adjusted_price,
        adjustment_pct: pricePreview.adjustment_pct,
        dynamic_pricing_name: pricePreview.dynamic_pricing_name,
        is_discount: pricePreview.is_discount,
        has_dynamic_pricing: pricePreview.has_dynamic_pricing,
      });
    } else {
      setDynamicPricing(null);
    }
  }, [pricePreview, setDynamicPricing]);

  // Build a map of date -> price data for quick lookup
  const priceMap = new Map(
    (priceCalendar ?? []).map((d) => [d.date, d]),
  );

  // Find the cheapest day (with discount)
  const cheapestDay = (priceCalendar ?? [])
    .filter((d) => d.has_dynamic_pricing && d.adjustment_pct < 0 && !d.closed)
    .sort((a, b) => a.adjustment_pct - b.adjustment_pct)[0] ?? null;

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

      {/* Cheapest day highlight */}
      {cheapestDay && (
        <div className="flex items-center gap-2 rounded-lg bg-green-50 border border-green-200 px-3 py-2">
          <Zap className="h-4 w-4 text-green-600 fill-green-600" />
          <p className="text-sm text-green-800">
            <span className="font-semibold">
              Día más económico:{' '}
              {parseDate(cheapestDay.date).format('dddd D [de] MMM')}
            </span>{' '}
            <span className="inline-flex items-center rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700">
              {cheapestDay.adjustment_pct}%
            </span>
          </p>
        </div>
      )}

      {/* Date selector with price badges */}
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
              const priceData = priceMap.get(date);
              const isClosed = priceData?.closed;
              const hasDynamic = priceData?.has_dynamic_pricing;
              const pct = priceData?.adjustment_pct ?? 0;

              return (
                <button
                  key={date}
                  type="button"
                  onClick={() => !isClosed && handleDateSelect(date)}
                  disabled={isClosed}
                  className={cn(
                    'flex shrink-0 flex-col items-center rounded-xl px-3 py-2 text-sm transition-all min-w-[60px] relative',
                    isClosed
                      ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                      : isSelected
                        ? 'bg-violet-600 text-white shadow-md'
                        : 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-200',
                  )}
                >
                  <span className="text-xs font-medium uppercase">
                    {dayName}
                  </span>
                  <span className="text-lg font-bold">{dayNum}</span>
                  <span className="text-xs">{monthName}</span>

                  {/* Price badge */}
                  {isClosed ? (
                    <span className="mt-1 text-[10px] font-medium text-gray-400">
                      Cerrado
                    </span>
                  ) : hasDynamic && pct !== 0 ? (
                    <span
                      className={cn(
                        'mt-1 flex items-center gap-0.5 rounded-full px-1.5 py-0.5 text-[10px] font-semibold',
                        pct < 0
                          ? isSelected
                            ? 'bg-green-200 text-green-800'
                            : 'bg-green-100 text-green-700'
                          : isSelected
                            ? 'bg-orange-200 text-orange-800'
                            : 'bg-orange-100 text-orange-700',
                      )}
                    >
                      <Zap className="h-2.5 w-2.5" />
                      {pct > 0 ? '+' : ''}{pct}%
                    </span>
                  ) : null}
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

      {/* Dynamic price display for selected date */}
      {pricePreview?.has_dynamic_pricing && pricePreview.adjustment_pct !== 0 ? (
        <div
          className={cn(
            'flex items-center justify-between rounded-lg border px-4 py-3',
            pricePreview.is_discount
              ? 'bg-green-50 border-green-200'
              : 'bg-orange-50 border-orange-200',
          )}
        >
          <div className="flex items-center gap-2">
            <Zap
              className={cn(
                'h-4 w-4',
                pricePreview.is_discount
                  ? 'text-green-600 fill-green-600'
                  : 'text-orange-600 fill-orange-600',
              )}
            />
            <div>
              <p className="text-sm font-medium text-gray-900">
                <span className="line-through text-gray-400 mr-2">
                  {formatCurrency(pricePreview.base_price)}
                </span>
                {formatCurrency(pricePreview.adjusted_price)}
              </p>
              <p
                className={cn(
                  'text-xs',
                  pricePreview.is_discount ? 'text-green-700' : 'text-orange-700',
                )}
              >
                {pricePreview.dynamic_pricing_name}
              </p>
            </div>
          </div>
          <span
            className={cn(
              'rounded-full px-2.5 py-1 text-xs font-semibold',
              pricePreview.is_discount
                ? 'bg-green-100 text-green-700'
                : 'bg-orange-100 text-orange-700',
            )}
          >
            {pricePreview.adjustment_pct > 0 ? '+' : ''}
            {pricePreview.adjustment_pct}%{' '}
            {pricePreview.is_discount ? 'Descuento' : 'Tarifa de temporada'}
          </span>
        </div>
      ) : null}

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
