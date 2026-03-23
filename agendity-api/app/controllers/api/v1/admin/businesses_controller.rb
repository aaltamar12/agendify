# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Lists businesses for the admin impersonation dropdown.
      # SRP: Only handles the admin business search HTTP concern.
      class BusinessesController < BaseController
        skip_before_action :render_empty_for_admin_without_business!
        before_action :require_admin!

        # GET /api/v1/admin/businesses?search=barber
        def index
          businesses = Business.order(:name)
          businesses = businesses.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

          render_success(
            businesses.limit(20).includes(subscriptions: :plan).map do |b|
              {
                id: b.id,
                name: b.name,
                slug: b.slug,
                business_type: b.business_type,
                status: b.status,
                plan_name: b.current_plan&.name,
                independent: b.independent?
              }
            end
          )
        end

        private

        def require_admin!
          unless current_user&.admin?
            render_error("Solo administradores pueden usar esta función", status: :forbidden)
          end
        end
      end
    end
  end
end
