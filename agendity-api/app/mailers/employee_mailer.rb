# frozen_string_literal: true

class EmployeeMailer < ApplicationMailer
  def invitation(invitation)
    @invitation = invitation
    @employee = invitation.employee
    @business = invitation.business
    @register_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/employee/register?token=#{invitation.token}"

    mail(
      to: invitation.email,
      subject: "Te invitaron a unirte a #{@business.name} en Agendity"
    )
  end
end
