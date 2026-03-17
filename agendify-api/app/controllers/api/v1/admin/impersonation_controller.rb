# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Allows superadmins to impersonate a business owner to view their dashboard.
      # SRP: Only handles impersonation start/stop HTTP concerns.
      #
      # TODO: The frontend impersonation dropdown currently shows a plain list of
      # businesses. Improve it to suggest 5 businesses based on stats:
      #   1. Highest activity (most appointments this week)
      #   2. Lowest activity (fewest appointments this month, but active)
      #   3. Newest signup (most recently created business)
      #   4. Expiring subscription (subscription ending within 7 days)
      #   5. Random active business (for spot-checking)
      # This would require a new endpoint: GET /api/v1/admin/suggested_businesses
      class ImpersonationController < BaseController
        before_action :require_admin!

        # POST /api/v1/admin/impersonate
        # Generates a JWT for the business owner so the admin can view
        # their dashboard. The admin's original token is returned so
        # the frontend can restore the session later.
        def create
          business = Business.find(params[:business_id])
          owner = business.owner

          token = Auth::TokenGenerator.encode(owner)

          render_success({
            token: token,
            user: UserSerializer.render_as_hash(owner),
            business: BusinessSerializer.render_as_hash(business),
            impersonating: true,
            admin_token: request.headers["Authorization"]&.split(" ")&.last
          })
        end

        # POST /api/v1/admin/stop_impersonation
        # No-op endpoint — the frontend restores the admin token client-side.
        # Exists for audit logging via RequestLogging concern.
        def destroy
          render_success({ message: "Impersonación finalizada" })
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
