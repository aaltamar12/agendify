# frozen_string_literal: true

module Api
  module V1
    # Manages discount codes for the current business.
    class DiscountCodesController < BaseController
      # GET /api/v1/discount_codes
      def index
        codes = current_business.discount_codes.order(created_at: :desc)
        codes = codes.where(active: true) if params[:active] == "true"
        codes = codes.where(source: params[:source]) if params[:source].present?
        render_success(DiscountCodeSerializer.render_as_hash(codes))
      end

      # POST /api/v1/discount_codes
      def create
        code = current_business.discount_codes.build(discount_code_params)
        code.source ||= "manual"

        if code.save
          render_success(DiscountCodeSerializer.render_as_hash(code), status: :created)
        else
          render_error(code.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      # DELETE /api/v1/discount_codes/:id
      def destroy
        code = current_business.discount_codes.find(params[:id])
        code.destroy!
        render_success({ deleted: true })
      end

      private

      def discount_code_params
        params.require(:discount_code).permit(
          :code, :name, :discount_type, :discount_value,
          :max_uses, :valid_from, :valid_until, :active, :source, :customer_id
        )
      end
    end
  end
end
