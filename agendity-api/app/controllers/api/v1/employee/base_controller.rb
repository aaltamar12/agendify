# frozen_string_literal: true

module Api
  module V1
    module Employee
      class BaseController < Api::V1::BaseController
        skip_before_action :require_business!
        skip_before_action :render_empty_for_admin_without_business!
        before_action :require_employee!

        private

        def require_employee!
          unless current_user&.employee?
            render json: { error: "Acceso solo para empleados" }, status: :forbidden
          end
        end

        def current_employee
          @current_employee ||= ::Employee.find_by(user_id: current_user.id)
        end
      end
    end
  end
end
