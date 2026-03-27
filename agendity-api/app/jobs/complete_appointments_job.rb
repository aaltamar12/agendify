# frozen_string_literal: true

# Scheduled job that marks checked-in appointments as completed
# when their end_time has passed, then triggers a rating request.
class CompleteAppointmentsJob < ApplicationJob
  queue_as :default

  def perform
    return record_success!("Skipped — disabled") unless job_enabled?

    now = Time.current
    tz = "America/Bogota"
    local_time_sql = "(end_time AT TIME ZONE 'UTC' AT TIME ZONE '#{tz}')::time"

    appointments = Appointment
      .includes(:business, :service, :employee, :customer)
      .where(status: :checked_in)
      .where(
        "appointment_date < :today OR (appointment_date = :today AND #{local_time_sql} < :now)",
        today: now.to_date, now: now.strftime("%H:%M")
      )

    appointments.find_each do |appointment|
      appointment.update!(status: :completed)

      ActivityLog.log(
        business: appointment.business,
        action: "appointment_completed",
        description: "Cita completada automáticamente: #{appointment.customer&.name}",
        actor_type: "system",
        resource: appointment
      )

      # Award cashback credits and notify customer
      cashback_result = Credits::CashbackService.call(appointment: appointment)
      if cashback_result.success? && cashback_result.data.present? && cashback_result.data.positive?
        SendCashbackNotificationJob.perform_later(appointment.id, cashback_result.data.to_f)
      end

      # Send rating request to customer
      SendRatingRequestJob.perform_later(appointment.id)

      # Real-time push
      Realtime::NatsPublisher.publish(
        business_id: appointment.business_id,
        event: "appointment_completed",
        data: {
          appointment_id: appointment.id,
          customer_name: appointment.customer&.name,
          service_name: appointment.service&.name
        }
      )
    end

    record_success!("Completed #{appointments.count} appointments")
  rescue StandardError => e
    record_error!(e.message)
    raise
  end
end
