# frozen_string_literal: true

# Notifies the business owner that a customer uploaded a payment proof
# and creates an in-app notification.
class SendPaymentSubmittedJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    payment = Payment.includes(appointment: [:business, :service, :employee, :customer]).find(payment_id)
    BusinessMailer.payment_submitted(payment).deliver_now

    appointment = payment.appointment

    # In-app notification for the business
    Notification.create!(
      business: appointment.business,
      title: "Comprobante de pago recibido de #{appointment.customer.name}",
      body: "#{appointment.service.name} — $#{payment.amount}",
      notification_type: "payment_submitted",
      link: "/dashboard/payments?tab=proofs&search=#{appointment.ticket_code}"
    )

    # Activity log
    ActivityLog.log(
      business: appointment.business,
      action: "notification_sent",
      description: "Notificación de comprobante enviada al negocio para #{appointment.customer&.name}",
      actor_type: "system",
      resource: appointment
    )

    # Real-time push via NATS
    Realtime::NatsPublisher.publish(
      business_id: appointment.business_id,
      event: "payment_submitted",
      data: {
        payment_id: payment.id,
        appointment_id: appointment.id,
        customer_name: appointment.customer&.name,
        amount: payment.amount
      }
    )
  end
end
