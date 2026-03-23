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

      # Validate consistency before closing
      recon = CashRegister::ReconciliationService.call(business: @business)
      if recon.success? && recon.data.any?
        names = recon.data.map { |d| d[:employee_name] }.join(", ")
        return failure("Hay inconsistencias en saldos de empleados (#{names}). Ejecuta una reconciliacion antes de cerrar caja.")
      end

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
          employee = @business.employees.find(ep[:employee_id])
          pending_prev = employee.pending_balance || 0
          commission = (ep[:commission_amount] || 0).to_d
          amount_paid = (ep[:amount_paid] || 0).to_d

          # For manual payment type: total_owed = what they paid (trust the owner)
          # This prevents reconciliation discrepancies from overpayments
          total_owed = if employee.manual?
                        [amount_paid, pending_prev].max
                      else
                        commission + pending_prev
                      end

          payment = close.employee_payments.find_or_initialize_by(employee_id: ep[:employee_id])
          payment.update!(
            appointments_count: ep[:appointments_count] || 0,
            total_earned: ep[:total_earned] || 0,
            commission_pct: ep[:commission_pct] || 0,
            commission_amount: commission,
            pending_from_previous: pending_prev,
            total_owed: total_owed,
            amount_paid: amount_paid,
            payment_method: ep[:payment_method] || :cash,
            notes: ep[:notes]
          )

          # Update employee pending balance: if paid less than owed, carry forward
          new_pending = [total_owed - amount_paid, 0].max
          employee.update!(pending_balance: new_pending)
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
