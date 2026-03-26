# frozen_string_literal: true

module Api
  module V1
    module Public
      # POST /api/v1/public/referral_codes
      # Creates a new referral code immediately (auto-generation, no admin approval).
      class ReferralSignupController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!
        skip_before_action :render_empty_for_admin_without_business!

        def create
          unless params[:referrer_name].present? && params[:referrer_email].present?
            return render_error("Nombre y email son requeridos", status: :unprocessable_entity)
          end

          # Return existing code if email already registered
          existing = ReferralCode.find_by(referrer_email: params[:referrer_email])
          if existing
            return render_success({
              code: existing.code,
              message: "Ya tienes un código de referido"
            })
          end

          referral_code = ReferralCode.create!(
            referrer_name: params[:referrer_name],
            referrer_email: params[:referrer_email],
            referrer_phone: params[:referrer_phone],
            bank_account: params[:bank_account],
            bank_name: params[:bank_name],
            breb_key: params[:breb_key],
            commission_percentage: 10,
            status: :active
          )

          render_success({
            code: referral_code.code,
            message: "Tu código de referido ha sido creado"
          }, status: :created)
        end
      end
    end
  end
end
