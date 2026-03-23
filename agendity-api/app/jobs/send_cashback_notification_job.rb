# frozen_string_literal: true

# Notifies the customer via email only when they receive cashback credits.
# WhatsApp is NOT used — cashback info is appended to existing WhatsApp messages
# (booking_confirmed) to avoid extra conversation costs.
class SendCashbackNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(appointment_id, cashback_amount)
    appointment = Appointment.includes(:customer, :service, :business).find(appointment_id)
    customer = appointment.customer
    business = appointment.business
    return unless customer.present? && customer.email.present?

    account = CreditAccount.find_by(customer: customer, business: business)
    new_balance = account&.balance || cashback_amount

    CustomerMailer.cashback_credited(customer, {
      business_name: business.name,
      service_name: appointment.service&.name,
      cashback_amount: cashback_amount,
      new_balance: new_balance,
      booking_url: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/#{business.slug}"
    }).deliver_now
  end
end
