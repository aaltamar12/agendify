# frozen_string_literal: true

module Api
  module V1
    class DynamicPricingController < BaseController
      before_action :require_professional_plan!

      # GET /api/v1/dynamic_pricing
      def index
        pricings = current_business.dynamic_pricings.order(start_date: :desc)
        pricings = pricings.where(status: params[:status]) if params[:status].present?
        render_success(DynamicPricingSerializer.render_as_hash(pricings))
      end

      # POST /api/v1/dynamic_pricing
      def create
        pricing = current_business.dynamic_pricings.build(pricing_params)
        pricing.suggested_by = "manual"
        pricing.status = :active

        if pricing.save
          render_success(DynamicPricingSerializer.render_as_hash(pricing), status: :created)
        else
          render_error(pricing.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      # PATCH /api/v1/dynamic_pricing/:id
      def update
        pricing = current_business.dynamic_pricings.find(params[:id])
        if pricing.update(pricing_params)
          render_success(DynamicPricingSerializer.render_as_hash(pricing))
        else
          render_error(pricing.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      # PATCH /api/v1/dynamic_pricing/:id/accept
      def accept
        pricing = current_business.dynamic_pricings.suggested.find(params[:id])
        pricing.update!(status: :active)
        render_success(DynamicPricingSerializer.render_as_hash(pricing))
      end

      # PATCH /api/v1/dynamic_pricing/:id/reject
      def reject
        pricing = current_business.dynamic_pricings.suggested.find(params[:id])
        pricing.update!(status: :rejected)
        render_success(DynamicPricingSerializer.render_as_hash(pricing))
      end

      # DELETE /api/v1/dynamic_pricing/:id
      def destroy
        pricing = current_business.dynamic_pricings.find(params[:id])
        pricing.destroy
        head :no_content
      end

      private

      def require_professional_plan!
        unless current_business.has_feature?(:advanced_reports)
          render_error("Las tarifas dinamicas requieren Plan Profesional o superior.", status: :forbidden)
        end
      end

      def pricing_params
        params.require(:dynamic_pricing).permit(
          :name, :service_id, :start_date, :end_date,
          :price_adjustment_type, :adjustment_mode,
          :adjustment_value, :adjustment_start_value, :adjustment_end_value,
          days_of_week: []
        )
      end
    end
  end
end
