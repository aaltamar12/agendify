# frozen_string_literal: true

module Appointments
  # Creates a new appointment after validating that the requested
  # employee can perform the service and the time slot is available.
  class CreateAppointmentService < BaseService
    def initialize(business:, params:, lock_token: nil)
      @business   = business
      @params     = params
      @lock_token = lock_token
    end

    def call
      # Reject bookings for past times
      if booking_in_the_past?
        return failure("No puedes agendar en un horario que ya pasó.", code: "SLOT_IN_PAST")
      end

      # Reject bookings on closed days
      if day_closed?
        return failure("El negocio no opera este dia. Selecciona otra fecha.", code: "BUSINESS_CLOSED")
      end

      service  = find_service
      return failure("Service not found or does not belong to this business", code: "SERVICE_NOT_FOUND") unless service

      additional_services = find_additional_services
      total_duration = service.duration_minutes + additional_services.sum(&:duration_minutes)

      employee = find_employee
      return failure("No hay profesionales disponibles para este horario. Intenta con otra hora.", code: "NO_EMPLOYEE_AVAILABLE") unless employee

      # Skip service check if employee was auto-assigned (already filtered by service)
      unless @params[:employee_id].blank?
        return failure("Este profesional no puede realizar este servicio", code: "EMPLOYEE_SERVICE_MISMATCH") unless employee_performs_service?(employee, service)
      end

      end_time = calculate_end_time(@params[:start_time], total_duration)

      ActiveRecord::Base.transaction do
        # Lock existing appointments for this employee+date to prevent race conditions
        @business.appointments
          .where(employee_id: employee.id, appointment_date: @params[:appointment_date])
          .lock("FOR UPDATE")
          .load

        if overlapping_appointment?(employee, @params[:appointment_date], @params[:start_time], end_time)
          return failure("Este horario ya no está disponible. Selecciona otro horario.", code: "SLOT_TAKEN")
        end

        if blocked_slot?(employee, @params[:appointment_date], @params[:start_time], end_time)
          return failure("Este horario está bloqueado.", code: "SLOT_BLOCKED")
        end

        customer = find_or_create_customer

        # Apply pending penalty from previous cancellations
        additional_services_price = additional_services.sum(&:price)
        final_price = service.price + additional_services_price
        original_price = final_price
        penalty_applied = 0
        dynamic_pricing = nil

        # Check for active dynamic pricing
        date = Date.parse(@params[:appointment_date].to_s) rescue Date.current
        active_pricing = @business.dynamic_pricings
          .for_date(date)
          .where("service_id = ? OR service_id IS NULL", service.id)
          .order(Arel.sql("service_id IS NOT NULL DESC"))
          .to_a
          .find { |p| p.applies_on_day?(date) }

        if active_pricing
          dynamic_pricing = active_pricing
          final_price = active_pricing.apply_to_price(final_price, date)
        end

        if customer.pending_penalty.positive?
          penalty_applied = customer.pending_penalty
          final_price += penalty_applied
          customer.update!(pending_penalty: 0)
        end

        # Apply credits if requested
        credits_applied = 0
        if @params[:apply_credits].present? && @params[:apply_credits].to_d > 0
          credit_account = CreditAccount.find_by(customer: customer, business: @business)
          if credit_account && credit_account.balance > 0
            credits_to_use = [@params[:apply_credits].to_d, credit_account.balance, final_price].min
            credit_account.debit!(
              credits_to_use,
              transaction_type: :redemption,
              description: "Creditos aplicados a reserva"
            )
            credits_applied = credits_to_use
            final_price -= credits_to_use
          end
        end

        appointment = @business.appointments.create!(
          service:          service,
          employee:         employee,
          customer:         customer,
          appointment_date: @params[:appointment_date],
          start_time:       @params[:start_time],
          end_time:         end_time,
          price:            final_price,
          original_price:   dynamic_pricing ? original_price : nil,
          dynamic_pricing_id: dynamic_pricing&.id,
          credits_applied:  credits_applied,
          notes:            @params[:notes],
          status:           credits_applied >= final_price + credits_applied ? :confirmed : :pending_payment,
          ticket_code:      generate_ticket_code
        )

        # Create records for additional services
        additional_services.each do |extra_service|
          appointment.appointment_services.create!(
            service: extra_service,
            price: extra_service.price,
            duration_minutes: extra_service.duration_minutes
          )
        end

        # Release the temporary slot lock now that the appointment is persisted
        release_slot_lock(appointment)

        ActivityLog.log(
          business: @business,
          action: "booking_created",
          description: "Nueva reserva: #{customer.name} reservó #{service.name}",
          actor_type: "customer",
          actor_name: customer.name,
          resource: appointment,
          metadata: { service_name: service.name, employee_name: employee.name, date: appointment.appointment_date.to_s }
        )

        success({ appointment: appointment, penalty_applied: penalty_applied })
      end
    rescue ActiveRecord::RecordNotUnique
      failure("Este horario acaba de ser reservado por otra persona. Selecciona otro horario.")
    rescue ActiveRecord::RecordInvalid => e
      failure("No se pudo crear la cita.", details: e.record.errors.full_messages)
    end

    private

    def find_service
      @business.services.find_by(id: @params[:service_id])
    end

    def find_employee
      if @params[:employee_id].present?
        @business.employees.active.find_by(id: @params[:employee_id])
      else
        # "Cualquier disponible" — find first available employee for this service
        assign_available_employee
      end
    end

    def find_additional_services
      ids = Array(@params[:additional_service_ids]).map(&:to_i).reject(&:zero?)
      return [] if ids.blank?

      @business.services.where(id: ids).to_a
    end

    def assign_available_employee
      service = @business.services.find_by(id: @params[:service_id])
      return nil unless service

      additional = find_additional_services
      total_duration = service.duration_minutes + additional.sum(&:duration_minutes)

      date = @params[:appointment_date]
      parsed_date = date.is_a?(String) ? Date.parse(date) : date
      start_time = @params[:start_time]
      end_time = calculate_end_time(start_time, total_duration)

      start_str = start_time.is_a?(String) ? start_time : start_time.strftime("%H:%M")
      end_str   = end_time.is_a?(String) ? end_time : end_time.strftime("%H:%M")

      # Try each active employee that can perform this service
      service.employees.active.shuffle.find do |emp|
        schedule = emp.employee_schedules.find_by(day_of_week: parsed_date.wday)
        next false unless schedule
        next false if start_str < schedule.start_time.strftime("%H:%M")
        next false if end_str > schedule.end_time.strftime("%H:%M")

        !overlapping_appointment?(emp, date, start_time, end_time) &&
          !blocked_slot?(emp, date, start_time, end_time)
      end
    end

    def employee_performs_service?(employee, service)
      employee.services.exists?(service.id)
    end

    def calculate_end_time(start_time, duration_minutes)
      parsed = start_time.is_a?(String) ? Time.parse(start_time) : start_time
      (parsed + duration_minutes.minutes).strftime("%H:%M")
    end

    def overlapping_appointment?(employee, date, start_time, end_time)
      @business.appointments
        .for_employee(employee.id)
        .on_date(date)
        .active
        .where("start_time < ? AND end_time > ?", end_time, start_time)
        .exists?
    end

    def blocked_slot?(employee, date, start_time, end_time)
      BlockedSlot.on_date(date)
        .where(business: @business)
        .where("employee_id IS NULL OR employee_id = ?", employee.id)
        .where("start_time < ? AND end_time > ?", end_time, start_time)
        .exists?
    end

    def find_or_create_customer
      if @params[:customer_email].present?
        @business.customers.find_or_create_by!(email: @params[:customer_email]) do |c|
          c.name  = @params[:customer_name]
          c.phone = @params[:customer_phone]
        end
      else
        @business.customers.create!(
          name:  @params[:customer_name],
          phone: @params[:customer_phone]
        )
      end
    end

    # Check if the business plan includes digital ticket feature
    def business_has_ticket_feature?
      @business.has_feature?(:ticket_digital)
    end

    def generate_ticket_code
      loop do
        code = SecureRandom.hex(6).upcase
        return code unless Appointment.exists?(ticket_code: code)
      end
    end

    def release_slot_lock(appointment)
      return unless @lock_token.present?

      Bookings::SlotLockService.unlock(
        business_id: @business.id,
        employee_id: appointment.employee_id,
        date:        appointment.appointment_date.to_s,
        time:        appointment.start_time.strftime("%H:%M"),
        token:       @lock_token
      )
    end

    def day_closed?
      date = @params[:appointment_date]
      parsed_date = date.is_a?(String) ? Date.parse(date) : date
      bh = @business.business_hours.find_by(day_of_week: parsed_date.wday)
      bh.nil? || bh.closed?
    end

    def booking_in_the_past?
      now = Time.current.in_time_zone(@business.timezone || "America/Bogota")
      date = @params[:appointment_date]
      parsed_date = date.is_a?(String) ? Date.parse(date) : date

      return true if parsed_date < now.to_date
      return false if parsed_date > now.to_date

      # Same day — check if the time has already passed
      start_time = @params[:start_time]
      time_str = start_time.is_a?(String) ? start_time : start_time.strftime("%H:%M")
      time_str <= now.strftime("%H:%M")
    end
  end
end
