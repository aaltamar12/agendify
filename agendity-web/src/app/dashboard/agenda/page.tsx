'use client';

import { Suspense, useState, useCallback, useEffect } from 'react';
import {
  ChevronLeft,
  ChevronRight,
  Plus,
  Ban,
} from 'lucide-react';
import { useSearchParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Select } from '@/components/ui/select';
import { Skeleton } from '@/components/ui/skeleton';
import { AgendaCalendar } from '@/components/agenda/agenda-calendar';
import { AppointmentDetailModal } from '@/components/agenda/appointment-detail-modal';
import { CreateAppointmentModal } from '@/components/agenda/create-appointment-modal';
import { BlockSlotModal } from '@/components/agenda/block-slot-modal';
import { useAppointments, useUpdateAppointment } from '@/lib/hooks/use-appointments';
import { useBlockedSlots } from '@/lib/hooks/use-blocked-slots';
import { useOnboardingProgress } from '@/lib/hooks/use-onboarding';
import { OnboardingChecklist } from '@/components/dashboard/onboarding-checklist';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import { now, parseDate } from '@/lib/utils/date';
import { useUIStore } from '@/lib/stores/ui-store';
import type { Appointment, Employee, ApiResponse } from '@/lib/api/types';

type CalendarView = 'timeGridDay' | 'timeGridWeek';

export default function AgendaPage() {
  return (
    <Suspense>
      <AgendaContent />
    </Suspense>
  );
}

function AgendaContent() {
  const addToast = useUIStore((s) => s.addToast);
  const searchParams = useSearchParams();

  // Current date and view state — initialize from ?date= query param if present
  const [currentDate, setCurrentDate] = useState(() => {
    const dateParam = searchParams.get('date');
    return dateParam || now().format('YYYY-MM-DD');
  });

  // Sync when navigating from a notification with a different date
  useEffect(() => {
    const dateParam = searchParams.get('date');
    if (dateParam && dateParam !== currentDate) {
      setCurrentDate(dateParam);
    }
  }, [searchParams]);
  const [view, setView] = useState<CalendarView>('timeGridDay');
  const [employeeFilter, setEmployeeFilter] = useState<string>('');

  // Modal state
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [selectedAppointment, setSelectedAppointment] = useState<Appointment | null>(null);
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [blockModalOpen, setBlockModalOpen] = useState(false);
  const [defaultDate, setDefaultDate] = useState<string>('');
  const [defaultTime, setDefaultTime] = useState<string>('');

  // Fetch employees for the filter
  const { data: employeesData } = useQuery({
    queryKey: ['employees'],
    queryFn: () => get<ApiResponse<Employee[]>>(ENDPOINTS.EMPLOYEES.list),
  });

  const employees = employeesData?.data ?? [];

  // Build query params
  const queryParams: Record<string, string | number> = { date: currentDate };
  if (employeeFilter) {
    queryParams.employee_id = Number(employeeFilter);
  }

  // Fetch appointments and blocked slots
  const {
    data: appointmentsData,
    isLoading: appointmentsLoading,
  } = useAppointments(queryParams);

  const {
    data: blockedSlotsData,
    isLoading: blockedSlotsLoading,
  } = useBlockedSlots(queryParams);

  const updateAppointment = useUpdateAppointment();
  const { data: onboardingData } = useOnboardingProgress();

  const appointments = appointmentsData?.data ?? [];
  const blockedSlots = blockedSlotsData?.data ?? [];
  const isLoading = appointmentsLoading || blockedSlotsLoading;

  // Employee filter options
  const employeeOptions = [
    { value: '', label: 'Todos los empleados' },
    ...employees
      .filter((e) => e.active)
      .map((e) => ({ value: String(e.id), label: e.name })),
  ];

  // Date navigation
  const goToPrevDay = useCallback(() => {
    setCurrentDate((d) => parseDate(d).subtract(1, 'day').format('YYYY-MM-DD'));
  }, []);

  const goToNextDay = useCallback(() => {
    setCurrentDate((d) => parseDate(d).add(1, 'day').format('YYYY-MM-DD'));
  }, []);

  const goToToday = useCallback(() => {
    setCurrentDate(now().format('YYYY-MM-DD'));
  }, []);

  // Format displayed date
  const displayDate = parseDate(currentDate);
  const isToday = displayDate.isSame(now(), 'day');
  const dateLabel = isToday
    ? 'Hoy'
    : displayDate.format('ddd, D [de] MMMM');

  // Event handlers
  function handleEventClick(appointment: Appointment) {
    setSelectedAppointment(appointment);
    setDetailModalOpen(true);
  }

  function handleDateClick(date: string, time: string) {
    setDefaultDate(date);
    setDefaultTime(time);
    setCreateModalOpen(true);
  }

  async function handleEventDrop(
    appointmentId: number,
    newDate: string,
    newTime: string,
  ) {
    try {
      await updateAppointment.mutateAsync({
        id: appointmentId,
        data: { appointment_date: newDate, start_time: newTime },
      });
      addToast({ type: 'success', message: 'Cita reprogramada' });
    } catch {
      addToast({ type: 'error', message: 'Error al reprogramar la cita' });
    }
  }

  function handleNewAppointment() {
    setDefaultDate(currentDate);
    setDefaultTime('');
    setCreateModalOpen(true);
  }

  function handleBlockSlot() {
    setDefaultDate(currentDate);
    setDefaultTime('');
    setBlockModalOpen(true);
  }

  return (
    <div className="flex h-full flex-col">
      {/* Onboarding checklist */}
      {onboardingData && !onboardingData.all_complete && <OnboardingChecklist />}

      {/* Top bar */}
      <div className="flex flex-col gap-3 border-b border-gray-200 bg-white px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
        {/* Left: Date navigation */}
        <div className="flex items-center gap-2">
          <button
            onClick={goToPrevDay}
            className="cursor-pointer rounded-lg p-1.5 text-gray-600 hover:bg-gray-100 transition-colors"
            aria-label="Día anterior"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>

          <div className="flex flex-col items-center min-w-[180px]">
            <h1 className="text-center text-base font-semibold capitalize text-gray-900 sm:text-lg">
              {dateLabel}
            </h1>
            <span className="flex items-center gap-1 text-xs text-gray-400">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-green-400 opacity-75" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-green-500" />
              </span>
              Se actualiza automaticamente
            </span>
          </div>

          <button
            onClick={goToNextDay}
            className="cursor-pointer rounded-lg p-1.5 text-gray-600 hover:bg-gray-100 transition-colors"
            aria-label="Día siguiente"
          >
            <ChevronRight className="h-5 w-5" />
          </button>

          {!isToday && (
            <Button variant="ghost" size="sm" onClick={goToToday}>
              Hoy
            </Button>
          )}
        </div>

        {/* Center: View switcher */}
        <div className="flex items-center gap-2">
          <div className="inline-flex rounded-lg border border-gray-200 bg-gray-50 p-0.5">
            <button
              onClick={() => setView('timeGridDay')}
              className={`cursor-pointer rounded-md px-3 py-1 text-sm font-medium transition-colors ${
                view === 'timeGridDay'
                  ? 'bg-white text-violet-700 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Día
            </button>
            <button
              onClick={() => setView('timeGridWeek')}
              className={`cursor-pointer rounded-md px-3 py-1 text-sm font-medium transition-colors ${
                view === 'timeGridWeek'
                  ? 'bg-white text-violet-700 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Semana
            </button>
          </div>
        </div>

        {/* Right: Employee filter + actions */}
        <div className="flex items-center gap-2">
          <Select
            options={employeeOptions}
            value={employeeFilter}
            onChange={(e) => setEmployeeFilter(e.target.value)}
            className="w-52"
          />

          <Button
            variant="ghost"
            size="sm"
            onClick={handleBlockSlot}
            title="Bloquear horario"
          >
            <Ban className="h-4 w-4" />
            <span className="hidden sm:inline ml-1">Bloquear</span>
          </Button>

          <Button size="sm" onClick={handleNewAppointment} className="hidden sm:inline-flex whitespace-nowrap">
            <Plus className="h-4 w-4" />
            <span className="ml-1">Nueva cita</span>
          </Button>
        </div>
      </div>

      {/* Status legend */}
      <div className="flex flex-wrap items-center gap-3 border-b border-gray-100 bg-white px-4 py-2">
        <span className="text-xs text-gray-400">Estados:</span>
        {[
          { color: '#F59E0B', label: 'Pendiente de pago' },
          { color: '#3B82F6', label: 'Comprobante enviado' },
          { color: '#10B981', label: 'Confirmada' },
          { color: '#7C3AED', label: 'En atención' },
          { color: '#6B7280', label: 'Completada' },
          { color: '#EF4444', label: 'Cancelada' },
        ].map((s) => (
          <span key={s.label} className="flex items-center gap-1.5 text-xs text-gray-600">
            <span
              className="inline-block h-2.5 w-2.5 rounded-full"
              style={{ backgroundColor: s.color }}
            />
            {s.label}
          </span>
        ))}
      </div>

      {/* Calendar area */}
      <div className="flex-1 overflow-auto bg-white">
        {isLoading ? (
          <div className="space-y-2 p-4">
            <Skeleton className="h-10 w-full" />
            <Skeleton className="h-[500px] w-full" />
          </div>
        ) : (
          <AgendaCalendar
            appointments={appointments}
            blockedSlots={blockedSlots}
            onEventClick={handleEventClick}
            onDateClick={handleDateClick}
            onEventDrop={handleEventDrop}
            view={view}
            date={currentDate}
          />
        )}
      </div>

      {/* Floating action button (mobile) */}
      <button
        onClick={handleNewAppointment}
        className="fixed bottom-6 right-6 flex h-14 w-14 items-center justify-center rounded-full bg-violet-600 text-white shadow-lg hover:bg-violet-700 transition-colors sm:hidden"
        aria-label="Nueva cita"
      >
        <Plus className="h-6 w-6" />
      </button>

      {/* Modals */}
      <AppointmentDetailModal
        open={detailModalOpen}
        onClose={() => {
          setDetailModalOpen(false);
          setSelectedAppointment(null);
        }}
        appointment={selectedAppointment}
      />

      <CreateAppointmentModal
        open={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        defaultDate={defaultDate}
        defaultTime={defaultTime}
      />

      <BlockSlotModal
        open={blockModalOpen}
        onClose={() => setBlockModalOpen(false)}
        defaultDate={defaultDate}
        defaultTime={defaultTime}
      />
    </div>
  );
}
