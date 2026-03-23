# frozen_string_literal: true

module Api
  module V1
    module Public
      # Public endpoint to validate a referral code during registration.
      class ReferralCodesController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!

        # GET /api/v1/public/referral_codes/:code/validate
        def validate
          code = ReferralCode.active.find_by("LOWER(code) = ?", params[:code]&.downcase)

          if code
            render_success({ valid: true, referrer_name: code.referrer_name })
          else
            render_success({ valid: false, referrer_name: nil })
          end
        end
      end
    end
  end
end
