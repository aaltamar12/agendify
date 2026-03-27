# frozen_string_literal: true

# Sends emails related to the referral program.
class ReferralMailer < ApplicationMailer
  def welcome(referral_code)
    @referral_code = referral_code
    @referral_link = "#{SiteConfig.get('app_url')}/register?ref=#{referral_code.code}"
    @dashboard_link = "#{SiteConfig.get('app_url')}/referral/dashboard?code=#{referral_code.code}"
    @conditions = "La comisión se genera cuando el negocio referido completa su periodo de prueba y se suscribe a cualquier plan de pago."
    @commission_percentage = referral_code.commission_percentage

    # Inline QR code of referral link
    qr_png = QrCodeHelper.url_qr_png(@referral_link)
    attachments.inline["referral_qr.png"] = qr_png

    mail(to: referral_code.referrer_email, subject: "Bienvenido al Programa de Referidos de Agendity")
  end
end
