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
end
