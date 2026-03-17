'use client';

import { useRef, useEffect } from 'react';
import FullCalendar from '@fullcalendar/react';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import type { EventClickArg, EventDropArg } from '@fullcalendar/core';
import type { DateClickArg } from '@fullcalendar/interaction';
import type { Appointment, BlockedSlot } from '@/lib/api/types';
import { APPOINTMENT_STATUSES } from '@/lib/constants';

type CalendarView = 'timeGridDay' | 'timeGridWeek';

interface AgendaCalendarProps {
  appointments: Appointment[];
  blockedSlots: BlockedSlot[];
  onEventClick: (appointment: Appointment) => void;
  onDateClick: (date: string, time: string) => void;
  onEventDrop: (appointmentId: number, newDate: string, newTime: string) => void;
  view: CalendarView;
  date: string;
}

export function AgendaCalendar({
  appointments,
  blockedSlots,
  onEventClick,
  onDateClick,
  onEventDrop,
  view,
  date,
}: AgendaCalendarProps) {
  const calendarRef = useRef<FullCalendar>(null);

  // Sync external date/view changes to FullCalendar
  useEffect(() => {
    const api = calendarRef.current?.getApi();
    if (!api) return;
    api.changeView(view);
    api.gotoDate(date);
  }, [view, date]);

  // Map appointments to FullCalendar events
  const appointmentEvents = appointments.map((appt) => {
    const statusConfig = APPOINTMENT_STATUSES[appt.status];
    const serviceName = appt.service?.name ?? 'Servicio';
    const customerName = appt.customer?.name ?? 'Cliente';

    return {
      id: `appointment-${appt.id}`,
      title: `${serviceName} - ${customerName}`,
      start: `${appt.date}T${appt.start_time}`,
      end: `${appt.date}T${appt.end_time}`,
      backgroundColor: statusConfig.color,
      borderColor: statusConfig.color,
      textColor: '#FFFFFF',
      editable: appt.status !== 'cancelled' && appt.status !== 'completed',
      extendedProps: {
        type: 'appointment' as const,
        appointment: appt,
      },
    };
  });

  // Map blocked slots to background events
  const blockedEvents = blockedSlots.map((slot) => ({
    id: `blocked-${slot.id}`,
    start: `${slot.date}T${slot.start_time}`,
    end: `${slot.date}T${slot.end_time}`,
    display: 'background' as const,
    backgroundColor: '#E5E7EB',
    extendedProps: {
      type: 'blocked' as const,
      blockedSlot: slot,
    },
  }));

  const allEvents = [...appointmentEvents, ...blockedEvents];

  function handleEventClick(info: EventClickArg) {
    const { type, appointment } = info.event.extendedProps;
    if (type === 'appointment' && appointment) {
      onEventClick(appointment as Appointment);
    }
  }

  function handleDateClick(info: DateClickArg) {
    const dateStr = info.dateStr.split('T')[0];
    const timeStr = info.dateStr.includes('T')
      ? info.dateStr.split('T')[1].slice(0, 5)
      : '09:00';
    onDateClick(dateStr, timeStr);
  }

  function handleEventDrop(info: EventDropArg) {
    const { type, appointment } = info.event.extendedProps;
    if (type !== 'appointment' || !appointment) {
      info.revert();
      return;
    }

    const newStart = info.event.start;
    if (!newStart) {
      info.revert();
      return;
    }

    const newDate = newStart.toISOString().split('T')[0];
    const hours = String(newStart.getHours()).padStart(2, '0');
    const minutes = String(newStart.getMinutes()).padStart(2, '0');
    const newTime = `${hours}:${minutes}`;

    onEventDrop((appointment as Appointment).id, newDate, newTime);
  }

  return (
    <div className="agenda-calendar flex-1 overflow-auto">
      <FullCalendar
        ref={calendarRef}
        plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin]}
        initialView={view}
        initialDate={date}
        locale="es"
        headerToolbar={false}
        nowIndicator={true}
        allDaySlot={false}
        slotMinTime="06:00:00"
        slotMaxTime="22:00:00"
        slotDuration="00:15:00"
        slotLabelInterval="01:00:00"
        slotLabelFormat={{
          hour: 'numeric',
          minute: '2-digit',
          meridiem: 'short',
        }}
        events={allEvents}
        editable={true}
        droppable={false}
        eventClick={handleEventClick}
        dateClick={handleDateClick}
        eventDrop={handleEventDrop}
        height="auto"
        expandRows={true}
        dayHeaderFormat={{ weekday: 'short', day: 'numeric' }}
        eventTimeFormat={{
          hour: 'numeric',
          minute: '2-digit',
          meridiem: 'short',
        }}
      />

      {/* Custom styles for FullCalendar — violet theme */}
      <style jsx global>{`
        .agenda-calendar .fc {
          --fc-border-color: #E5E7EB;
          --fc-today-bg-color: #F5F3FF;
          --fc-now-indicator-color: #7C3AED;
          --fc-event-border-color: transparent;
          font-family: inherit;
        }

        .agenda-calendar .fc .fc-timegrid-slot {
          height: 2.5rem;
        }

        .agenda-calendar .fc .fc-timegrid-event {
          border-radius: 0.375rem;
          padding: 2px 4px;
          font-size: 0.75rem;
          line-height: 1.1;
          border: none;
        }

        .agenda-calendar .fc .fc-timegrid-event .fc-event-title {
          font-weight: 500;
        }

        .agenda-calendar .fc .fc-col-header-cell {
          padding: 0.5rem 0;
          font-size: 0.875rem;
          font-weight: 600;
          color: #374151;
        }

        .agenda-calendar .fc .fc-timegrid-slot-label {
          font-size: 0.75rem;
          color: #6B7280;
        }

        .agenda-calendar .fc .fc-timegrid-now-indicator-line {
          border-color: #7C3AED;
          border-width: 2px;
        }

        .agenda-calendar .fc .fc-timegrid-now-indicator-arrow {
          border-color: #7C3AED;
        }

        .agenda-calendar .fc .fc-scrollgrid {
          border: none;
        }

        .agenda-calendar .fc .fc-scrollgrid-section > * {
          border: none;
        }

        .agenda-calendar .fc .fc-day-today .fc-col-header-cell-cushion {
          color: #7C3AED;
          font-weight: 700;
        }
      `}</style>
    </div>
  );
}
