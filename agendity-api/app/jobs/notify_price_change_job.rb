# frozen_string_literal: true

# Sends a price-change notification email to every business with an active subscription.
# Intended to be triggered manually from a console or admin action, NOT on a recurring schedule.
#
# Usage:
#   NotifyPriceChangeJob.perform_later(
#     old_prices: { "Profesional" => 49_900, "Pro+" => 99_900 },
#     new_prices: { "Profesional" => 59_900, "Pro+" => 119_900 },
#     effective_date: "2026-05-01"
#   )
class NotifyPriceChangeJob < ApplicationJob
  queue_as :mailers

  def perform(old_prices:, new_prices:, effective_date:)
    effective = effective_date.is_a?(String) ? Date.parse(effective_date) : effective_date
    sent = 0

    Business.joins(:subscriptions)
            .merge(Subscription.active)
            .distinct
            .includes(:owner)
            .find_each do |business|
      BusinessMailer.price_change_notification(
        business,
        old_prices,
        new_prices,
        effective
      ).deliver_later

      sent += 1
    end

    record_success!("Emails queued: #{sent}")
  rescue StandardError => e
    record_error!(e.message)
    raise
  end
end
