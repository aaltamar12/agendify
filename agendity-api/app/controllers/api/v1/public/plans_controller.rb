# frozen_string_literal: true

module Api
  module V1
    module Public
      # Returns available subscription plans with pricing.
      # No authentication required — used by landing page and public screens.
      class PlansController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!
        skip_before_action :render_empty_for_admin_without_business!

        # GET /api/v1/public/plans
        def index
          plans = Plan.order(:price_monthly)
          render_success(plans.map { |p|
            {
              id: p.id,
              name: p.name,
              price_monthly: p.price_monthly.to_f,
              price_monthly_usd: p.price_monthly_usd&.to_f,
              max_employees: p.max_employees,
              max_services: p.max_services,
              features: p.features || []
            }
          })
        end
      end
    end
  end
end
