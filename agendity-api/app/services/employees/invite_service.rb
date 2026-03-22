# frozen_string_literal: true

module Employees
  # Generates an invitation for an employee to create their account.
  class InviteService < BaseService
    def initialize(employee:, email:)
      @employee = employee
      @email = email
    end

    def call
      return failure("El empleado ya tiene una cuenta vinculada") if @employee.user_id.present?

      invitation = @employee.employee_invitations.create!(
        business: @employee.business,
        email: @email
      )

      EmployeeMailer.invitation(invitation).deliver_later

      success(invitation)
    end
  end
end
