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

  def birthday_greeting(customer, data)
    @customer = customer
    @business_name = data[:business_name]
    @discount_pct = data[:discount_pct]
    @code = data[:code]
    @valid_until = data[:valid_until]
    @booking_url = data[:booking_url]

    mail(
      to: @customer.email,
      subject: "Feliz cumpleanos #{@customer.name}! #{@business_name} te tiene un regalo"
    )
  end

  def credits_adjusted(customer, data)
    @customer = customer
    @business_name = data[:business_name]
    @amount = data[:amount]
    @new_balance = data[:new_balance]
    @description = data[:description]
    @booking_url = data[:booking_url]

    mail(
      to: @customer.email,
      subject: "Recibiste créditos de #{@business_name}"
    )
  end
end
