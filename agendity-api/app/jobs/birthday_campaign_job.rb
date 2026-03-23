# frozen_string_literal: true

# Runs daily at 8am. For each business with birthday_campaign_enabled,
# finds customers whose birthday is today, generates a discount code,
# and sends a greeting via email (+ WhatsApp for Pro+).
class BirthdayCampaignJob < ApplicationJob
  queue_as :default

  def perform
    return unless job_enabled?

    today = Date.current
    month = today.month
    day = today.day
    total_codes = 0

    Business.active.where(birthday_campaign_enabled: true).find_each do |business|
      business.customers.with_email.with_birthday_on(month, day).find_each do |customer|
        code = generate_birthday_code(business, customer)
        send_birthday_greeting(business, customer, code)
        log_activity(business, customer, code)
        total_codes += 1
      end
    end

    @_already_recorded = true
    record_success!("Generated #{total_codes} birthday codes")
  end

  private

  def generate_birthday_code(business, customer)
    business.discount_codes.create!(
      name: "Cumpleanos #{customer.name}",
      discount_type: "percentage",
      discount_value: business.birthday_discount_pct || 10,
      max_uses: 1,
      valid_from: Date.current,
      valid_until: Date.current + (business.birthday_discount_days_valid || 7).days,
      source: "birthday",
      customer: customer
    )
  end

  def send_birthday_greeting(business, customer, code)
    booking_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/#{business.slug}"

    Notifications::MultiChannelService.call(
      recipient: customer,
      template: :birthday_greeting,
      business: business,
      data: {
        customer: customer,
        business: business,
        discount_code: code,
        business_name: business.name,
        discount_pct: code.discount_value.to_i,
        code: code.code,
        valid_until: code.valid_until,
        booking_url: booking_url
      }
    )
  end

  def log_activity(business, customer, code)
    ActivityLog.log(
      business: business,
      action: "birthday_campaign_sent",
      description: "Felicitacion de cumpleanos enviada a #{customer.name} con codigo #{code.code}",
      actor_type: "system",
      actor_name: "BirthdayCampaignJob",
      metadata: {
        customer_id: customer.id,
        discount_code_id: code.id,
        discount_code: code.code,
        discount_pct: code.discount_value.to_i
      }
    )
  end
end
