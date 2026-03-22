# frozen_string_literal: true

module CashRegister
  # Creates a cash register close record for a given date.
  class CloseService < BaseService
    def initialize(business:, user:, date:, employee_payments:, notes: nil)
      @business = business
      @user = user
      @date = date.is_a?(String) ? Date.parse(date) : date
      @employee_payments = employee_payments || []
      @notes = notes
    end

    def call
      return failure("No se puede cerrar caja de un día futuro") if @date > Date.current

      existing = @business.cash_register_closes.find_by(date: @date)
      return failure("Ya se cerró caja de este día") if existing&.closed?

      appointments = @business.appointments
        .where(appointment_date: @date)
        .where(status: [:checked_in, :completed])

      close = existing || @business.cash_register_closes.new(date: @date)
      close.assign_attributes(
        closed_by_user: @user,
        closed_at: Time.current,
        total_revenue: appointments.sum(:price),
        total_appointments: appointments.size,
        notes: @notes,
        status: :closed
      )

      ActiveRecord::Base.transaction do
        close.save!

        @employee_payments.each do |ep|
          payment = close.employee_payments.find_or_initialize_by(employee_id: ep[:employee_id])
          payment.update!(
            appointments_count: ep[:appointments_count] || 0,
            total_earned: ep[:total_earned] || 0,
            commission_pct: ep[:commission_pct] || 0,
            commission_amount: ep[:commission_amount] || 0,
            amount_paid: ep[:amount_paid] || 0,
            payment_method: ep[:payment_method] || :cash,
            notes: ep[:notes]
          )
        end
      end

      ActivityLog.log(
        business: @business,
        action: "cash_register_closed",
        description: "Cierre de caja del #{@date} - Total: $#{close.total_revenue.to_i}",
        actor_type: "business",
        resource: close
      )

      success(close.reload)
    end
  end
end
