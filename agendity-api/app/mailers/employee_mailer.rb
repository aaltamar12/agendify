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

  def payment_receipt(employee_payment)
    @employee_payment = employee_payment
    @employee = employee_payment.employee
    @close = employee_payment.cash_register_close
    @business = @close.business
    @date = @close.date

    mail(
      to: @employee.email,
      subject: "Recibo de pago — #{@business.name} — #{@date.strftime('%d/%m/%Y')}"
    )
  end
end
