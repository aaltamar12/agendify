# frozen_string_literal: true

module Api
  module V1
    # Public endpoints for employee invitation flow (no auth required).
    class EmployeeInvitationsController < BaseController
      skip_before_action :authenticate_user!
      skip_before_action :require_business!
      skip_before_action :render_empty_for_admin_without_business!

      # GET /api/v1/employee_invitations/:token
      def show
        invitation = EmployeeInvitation.includes(:employee, :business).find_by!(token: params[:token])

        render_success({
          employee_name: invitation.employee.name,
          business_name: invitation.business.name,
          email: invitation.email,
          expired: invitation.expired?,
          accepted: invitation.accepted?
        })
      end

      # POST /api/v1/employee_invitations/:token/accept
      def accept
        result = Employees::AcceptInvitationService.call(
          token: params[:token],
          password: params[:password],
          password_confirmation: params[:password_confirmation]
        )

        if result.success?
          render_success(result.data, status: :created)
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end
    end
  end
end
