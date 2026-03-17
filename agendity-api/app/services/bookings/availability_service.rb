# frozen_string_literal: true

module Bookings
  # Calculates available time slots for a given business, service,
  # optional employee, and date.  Returns an array of hashes
  # with :time and :available keys.
  class AvailabilityService < BaseService
    def initialize(business:, service_id:, date:, employee_id: nil)
      @business    = business
      @service_id  = service_id
      @date        = date.is_a?(String) ? Date.parse(date) : date
      @employee_id = employee_id
    end

    def call
      service = @business.services.find_by(id: @service_id)
      return failure("Service not found") unless service

      employees = resolve_employees(service)
      return failure("No employees available for this service") if employees.empty?

      business_hours = @business.business_hours.for_day(@date.wday)
      return success([]) unless business_hours && !business_hours.closed?

      slots = generate_slots(business_hours, service, employees)
      success(slots)
    end

    private

    def slot_interval
      @business.slot_interval_minutes || 30
    end

    def gap_minutes
      @business.gap_between_appointments_minutes || 0
    end

    def resolve_employees(service)
      scope = service.employees.active
      scope = scope.where(id: @employee_id) if @employee_id.present?
      scope.to_a
    end

    def generate_slots(business_hours, service, employees)
      open_time  = business_hours.open_time
      close_time = business_hours.close_time
      duration   = service.duration_minutes

      # Get current time in business timezone to filter past slots
      now = Time.current.in_time_zone(@business.timezone || "America/Bogota")
      is_today = @date == now.to_date

      # Lunch break boundaries (as HH:MM strings for comparison)
      lunch_start = @business.lunch_start_time
      lunch_end   = @business.lunch_end_time

      slots = []
      current = open_time

      while (current + duration.minutes) <= close_time
        slot_start_str = current.strftime("%H:%M")

        # Skip past slots if booking for today
        if is_today && current.strftime("%H:%M:%S") <= now.strftime("%H:%M:%S")
          slots << { time: slot_start_str, available: false }
          current += slot_interval.minutes
          next
        end

        # Skip lunch break
        if @business.lunch_enabled && lunch_start.present? && lunch_end.present?
          slot_end_str = (current + duration.minutes).strftime("%H:%M")
          if slot_start_str < lunch_end && slot_end_str > lunch_start
            slots << { time: slot_start_str, available: false }
            current += slot_interval.minutes
            next
          end
        end

        available = employees.any? { |emp| slot_available?(emp, current, duration) }
        slots << { time: slot_start_str, available: available }
        current += slot_interval.minutes
      end

      slots
    end

    def slot_available?(employee, start_time, duration_minutes)
      end_time = start_time + duration_minutes.minutes

      # Check employee schedule for the day
      schedule = employee.employee_schedules.find_by(day_of_week: @date.wday)
      return false unless schedule
      return false if start_time < schedule.start_time || end_time > schedule.end_time

      # Check overlapping appointments (including gap between appointments)
      gap = gap_minutes
      query_start = end_time.strftime("%H:%M")
      query_end   = start_time.strftime("%H:%M")

      active_appointments = @business.appointments
        .for_employee(employee.id)
        .on_date(@date)
        .active

      has_overlap = active_appointments
        .where("start_time < ? AND end_time > ?", query_start, query_end)
        .exists?
      return false if has_overlap

      # Check gap: no appointment should end within gap_minutes before our start
      if gap > 0
        gap_boundary = (start_time - gap.minutes).strftime("%H:%M")
        has_gap_conflict = active_appointments
          .where("end_time > ? AND end_time <= ?", gap_boundary, start_time.strftime("%H:%M"))
          .exists?
        return false if has_gap_conflict
      end

      # Check blocked slots
      has_block = BlockedSlot.on_date(@date)
        .where(business: @business)
        .where("employee_id IS NULL OR employee_id = ?", employee.id)
        .where("start_time < ? AND end_time > ?", end_time.strftime("%H:%M"), start_time.strftime("%H:%M"))
        .exists?
      return false if has_block

      # Check if slot is temporarily locked by another user
      return false if Bookings::SlotLockService.locked?(
        business_id: @business.id,
        employee_id: employee.id,
        date:        @date.to_s,
        time:        start_time.strftime("%H:%M")
      )

      true
    end
  end
end
