# frozen_string_literal: true

# Sends a rating request to the customer after appointment completion
# using the multi-channel notification service.
class SendRatingRequestJob < ApplicationJob
  queue_as :notifications

  def perform(appointment_id)
    appointment = Appointment.includes(:customer, :service, :business).find(appointment_id)
    customer = appointment.customer
    return unless customer&.email.present?

    business = appointment.business
    channels = business.notification_channels_for(:rating_request)

    Notifications::MultiChannelService.call(
      recipient: customer,
      template: :rating_request,
      data: {
        business_name: business.name,
        service_name: appointment.service.name,
        appointment_date: appointment.appointment_date,
        review_url: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/#{business.slug}#reviews"
      },
      channels: channels
    )
  end
end
