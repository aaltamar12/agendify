# frozen_string_literal: true

module Employees
  # Accepts an invitation: creates a User with role employee and links it to the Employee.
  class AcceptInvitationService < BaseService
    def initialize(token:, password:, password_confirmation:)
      @token = token
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      invitation = EmployeeInvitation.find_by(token: @token)
      return failure("Invitacion no encontrada") unless invitation
      return failure("La invitacion ha expirado") if invitation.expired?
      return failure("La invitacion ya fue aceptada") if invitation.accepted?

      employee = invitation.employee
      return failure("El empleado ya tiene una cuenta") if employee.user_id.present?

      user = User.new(
        name: employee.name,
        email: invitation.email,
        password: @password,
        password_confirmation: @password_confirmation,
        role: :employee
      )

      unless user.save
        return failure(user.errors.full_messages.to_sentence, details: user.errors.messages)
      end

      employee.update!(user_id: user.id)
      invitation.update!(accepted_at: Time.current)

      # Generate JWT token for auto-login
      token = Auth::TokenGenerator.encode(user)
      refresh = RefreshToken.create!(user: user, token: SecureRandom.hex(32), expires_at: 30.days.from_now)

      success({
        token: token,
        refresh_token: refresh.token,
        user: UserSerializer.render_as_hash(user)
      })
    end
  end
end
