# frozen_string_literal: true

# Scheduled job that marks checked-in appointments as completed
# when their end_time has passed, then triggers a rating request.
class CompleteAppointmentsJob < ApplicationJob
  queue_as :default

  def perform
    appointments = Appointment
      .includes(:business, :service, :employee, :customer)
      .where(status: :checked_in)
      .where("appointment_date < ? OR (appointment_date = ? AND end_time < ?)",
             Date.current, Date.current, Time.current.strftime("%H:%M"))

    appointments.find_each do |appointment|
      appointment.update!(status: :completed)

      ActivityLog.log(
        business: appointment.business,
        action: "appointment_completed",
        description: "Cita completada automáticamente: #{appointment.customer&.name}",
        actor_type: "system",
        resource: appointment
      )

      # Award cashback credits
      Credits::CashbackService.call(appointment: appointment)

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

    Rails.logger.info("[CompleteAppointmentsJob] Completed #{appointments.count} appointments")
  end
end
