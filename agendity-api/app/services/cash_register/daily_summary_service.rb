# frozen_string_literal: true

module CashRegister
  # Calculates the daily summary for cash register closing.
  class DailySummaryService < BaseService
    def initialize(business:, date:)
      @business = business
      @date = date.is_a?(String) ? Date.parse(date) : date
    end

    def call
      appointments = @business.appointments
        .includes(:service, :employee, :customer)
        .where(appointment_date: @date)
        .where(status: [:checked_in, :completed])

      employee_breakdown = appointments.group_by(&:employee).map do |employee, appts|
        revenue = appts.sum(&:price)
        commission_pct = employee.commission_percentage || 0
        commission = (revenue * commission_pct / 100).round(2)

        pending = employee.pending_balance || 0

        {
          employee_id: employee.id,
          employee_name: employee.name,
          appointments_count: appts.size,
          total_earned: revenue.to_f,
          commission_pct: commission_pct.to_f,
          commission_amount: commission.to_f,
          pending_from_previous: pending.to_f,
          total_owed: (commission + pending).to_f,
          appointments: appts.map do |a|
            {
              id: a.id,
              customer_name: a.customer&.name,
              service_name: a.service&.name,
              start_time: a.start_time&.strftime("%H:%M"),
              price: a.price.to_f,
              status: a.status
            }
          end
        }
      end

      existing_close = @business.cash_register_closes.find_by(date: @date)

      success({
        date: @date,
        total_revenue: appointments.sum(:price).to_f,
        total_appointments: appointments.size,
        employees: employee_breakdown,
        already_closed: existing_close&.closed?,
        close_id: existing_close&.id
      })
    end
  end
end
