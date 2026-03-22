# frozen_string_literal: true

module Intelligence
  # Runs demand analysis for all businesses with Plan Inteligente
  # and generates dynamic pricing suggestions.
  class PricingSuggestionJob < ApplicationJob
    queue_as :intelligence

    def perform
      Business.joins(subscriptions: :plan)
              .where(plans: { ai_features: true })
              .where(businesses: { status: :active })
              .distinct
              .find_each do |business|
        next if business.appointments.count < 30

        result = Intelligence::DemandAnalysisService.call(business: business)

        if result.success? && result.data.any?
          Notification.create!(
            business: business,
            title: "Sugerencias de tarifas dinamicas",
            body: "Detectamos #{result.data.size} oportunidad(es) para optimizar tus precios.",
            notification_type: "ai_suggestion",
            link: "/dashboard/dynamic-pricing"
          )

          Realtime::NatsPublisher.publish(
            business_id: business.id,
            event: "ai_suggestion",
            data: { count: result.data.size, type: "dynamic_pricing" }
          )
        end
      rescue StandardError => e
        Rails.logger.error("[PricingSuggestionJob] Error for business #{business.id}: #{e.message}")
      end
    end
  end
end
