# frozen_string_literal: true

module Api
  module V1
    module Public
      # Returns public platform configuration (contact info, payment data).
      # No authentication required.
      class SiteConfigController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!
        skip_before_action :render_empty_for_admin_without_business!

        # GET /api/v1/public/site_config
        def show
          render_success({
            support_email: SiteConfig.get("support_email"),
            support_whatsapp: SiteConfig.get("support_whatsapp"),
            support_whatsapp_url: SiteConfig.get("support_whatsapp").present? ? "https://wa.me/#{SiteConfig.get('support_whatsapp').gsub(/\D/, '')}" : nil,
            payment_nequi: SiteConfig.get("payment_nequi"),
            payment_bancolombia: SiteConfig.get("payment_bancolombia"),
            payment_daviplata: SiteConfig.get("payment_daviplata"),
            company_name: SiteConfig.get("company_name") || "Agendity",
            default_trial_days: (SiteConfig.get("default_trial_days") || "7").to_i,
            referral_trial_days: (SiteConfig.get("referral_trial_days") || "25").to_i,
            tawkto_property_id: SiteConfig.get("tawkto_property_id")
          })
        end
      end
    end
  end
end
