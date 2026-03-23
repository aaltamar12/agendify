# frozen_string_literal: true

# Sends transactional emails to end users (customers).
class CustomerMailer < ApplicationMailer
  def rating_request(customer, data)
    @customer = customer
    @business_name = data[:business_name]
    @service_name = data[:service_name]
    @review_url = data[:review_url]

    mail(
      to: @customer.email,
      subject: "¿Cómo fue tu experiencia en #{@business_name}?"
    )
  end

  def cashback_credited(customer, data)
    @customer = customer
    @business_name = data[:business_name]
    @service_name = data[:service_name]
    @cashback_amount = data[:cashback_amount]
    @new_balance = data[:new_balance]
    @booking_url = data[:booking_url]

    mail(
      to: @customer.email,
      subject: "Ganaste créditos en #{@business_name}"
    )
  end
end
