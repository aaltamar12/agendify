# frozen_string_literal: true

module Api
  module V1
    module Public
      # GET  /api/v1/public/referral_codes/:code/dashboard
      # PATCH /api/v1/public/referral_codes/:code
      class ReferralDashboardController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!
        skip_before_action :render_empty_for_admin_without_business!

        # GET /api/v1/public/referral_codes/:code/dashboard
        def show
          referral_code = ReferralCode.find_by!(code: params[:code].upcase)

          referrals = referral_code.referrals.includes(business: { subscriptions: :plan })
          app_url = SiteConfig.get("app_url") || "https://agendity.co"

          referral_data = referrals.map do |referral|
            business = referral.business
            active_sub = business.subscriptions.active.order(created_at: :desc).first

            trial_days_remaining = business.trial_ends_at ? (business.trial_ends_at.to_date - Date.current).to_i : nil
            trial_expired = business.trial_ends_at ? business.trial_ends_at < Time.current : false

            {
              business_name: business.name,
              business_type: business.business_type,
              registered_at: business.created_at.to_date,
              trial_ends_at: business.trial_ends_at&.to_date,
              trial_days_remaining: trial_days_remaining,
              trial_expired: trial_expired,
              has_subscription: active_sub.present?,
              plan_name: active_sub&.plan&.name,
              referral_status: referral.status,
              commission_amount: referral.commission_amount,
              disbursement_requested_at: referral.disbursement_requested_at,
              disbursement_paid_at: referral.disbursement_paid_at,
              disbursement_proof_url: referral.disbursement_proof_url,
              disbursement_notes: referral.disbursement_notes
            }
          end

          active_subs_count = referrals.count { |r| r.activated? || r.paid? }
          total_earned = referrals.select { |r| r.activated? || r.paid? }.sum(&:commission_amount).to_i
          pending_commission = referrals.select(&:activated?).sum(&:commission_amount).to_i
          paid_commission = referrals.select(&:paid?).sum(&:commission_amount).to_i

          # Disbursements summary (activated with request or paid)
          disbursement_referrals = referrals.select { |r| r.disbursement_requested_at.present? || r.paid? }
          disbursements = disbursement_referrals.map do |referral|
            {
              referral_id: referral.id,
              business_name: referral.business.name,
              amount: referral.commission_amount.to_i,
              status: referral.paid? ? "paid" : "requested",
              requested_at: referral.disbursement_requested_at&.to_date,
              paid_at: referral.disbursement_paid_at&.to_date,
              proof_url: referral.disbursement_proof_url,
              notes: referral.disbursement_notes
            }
          end

          render_success({
            referrer: {
              name: referral_code.referrer_name,
              email: referral_code.referrer_email,
              phone: referral_code.referrer_phone,
              code: referral_code.code,
              bank_name: referral_code.bank_name,
              bank_account: referral_code.bank_account,
              breb_key: referral_code.breb_key,
              commission_percentage: referral_code.commission_percentage.to_i
            },
            stats: {
              total_referrals: referrals.size,
              active_subscriptions: active_subs_count,
              total_earned: total_earned,
              pending_commission: pending_commission,
              paid_commission: paid_commission
            },
            referrals: referral_data,
            disbursements: disbursements,
            referral_link: "#{app_url}/r/#{referral_code.code}",
            conditions: "La comisión se genera cuando el negocio referido completa su periodo de prueba y se suscribe a cualquier plan."
          })
        rescue ActiveRecord::RecordNotFound
          render_error("Código de referido no encontrado", status: :not_found)
        end

        # POST /api/v1/public/referral_codes/:code/request_disbursement
        def request_disbursement
          referral_code = ReferralCode.active.find_by!("UPPER(code) = ?", params[:code].upcase)

          # Find activated referrals that haven't been requested yet
          pending = referral_code.referrals.where(status: :activated, disbursement_requested_at: nil)
          count = pending.count

          if count.zero?
            return render_error("No hay comisiones pendientes de solicitar", status: :unprocessable_entity)
          end

          pending.update_all(disbursement_requested_at: Time.current)

          # Notify admin
          AdminNotification.notify!(
            title: "Solicitud de desembolso",
            body: "#{referral_code.referrer_name} solicita desembolso de #{count} comisiones",
            notification_type: "referral_disbursement",
            link: "/admin/referral_codes/#{referral_code.id}"
          )

          render_success({ requested: count, message: "Solicitud enviada. El equipo procesará tu desembolso." })
        rescue ActiveRecord::RecordNotFound
          render_error("Código de referido no encontrado", status: :not_found)
        end

        # PATCH /api/v1/public/referral_codes/:code
        def update
          referral_code = ReferralCode.find_by!(code: params[:code].upcase)

          referral_code.update!(update_params)

          render_success({
            message: "Información actualizada correctamente",
            referrer: {
              name: referral_code.referrer_name,
              email: referral_code.referrer_email,
              phone: referral_code.referrer_phone,
              bank_name: referral_code.bank_name,
              bank_account: referral_code.bank_account,
              breb_key: referral_code.breb_key
            }
          })
        rescue ActiveRecord::RecordNotFound
          render_error("Código de referido no encontrado", status: :not_found)
        end

        private

        def update_params
          params.permit(:referrer_name, :referrer_email, :referrer_phone, :bank_name, :bank_account, :breb_key)
        end
      end
    end
  end
end
