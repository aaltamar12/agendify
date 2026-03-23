# frozen_string_literal: true

# A business subscription to a plan.
class Subscription < ApplicationRecord
  include BusinessScoped

  # -- Enums --
  enum :status, { active: 0, expired: 1, cancelled: 2 }

  # -- Associations --
  belongs_to :plan
  has_many :subscription_payment_orders, dependent: :destroy

  # -- Validations --
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, presence: true

  # -- Scopes --
  scope :active, -> { where(status: :active) }
  scope :current, -> { active.where("end_date >= ?", Date.current) }
  scope :expiring_in, ->(days) { active.where(end_date: Date.current + days) }
  scope :expired_since, ->(days) { active.where(end_date: Date.current - days) }

  # -- Renewal --
  # Call this method when a subscription is renewed (admin confirms payment).
  # Sends confirmation notifications and reactivates the business if suspended.
  def process_renewal!(new_end_date: nil)
    new_end_date ||= end_date + 1.month

    transaction do
      update!(
        end_date: new_end_date,
        status: :active,
        expiry_alert_stage: 0
      )

      # Reactivate business if it was suspended
      business.active! if business.suspended?
    end

    # Send renewal confirmation notifications (outside transaction)
    send_renewal_notifications!
  end

  # -- Ransack (ActiveAdmin filters) --
  def self.ransackable_attributes(_auth_object = nil)
    %w[status start_date end_date business_id plan_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[business plan]
  end

  private

  def send_renewal_notifications!
    # Email
    BusinessMailer.subscription_renewed(business, self).deliver_later

    # In-app notification
    notification = Notification.create!(
      business: business,
      title: "Suscripción renovada",
      body: "Tu plan #{plan.name} ha sido renovado hasta el #{end_date.strftime('%d/%m/%Y')}.",
      notification_type: "subscription_expiry",
      link: "/dashboard/settings"
    )

    # Real-time push via NATS
    Realtime::NatsPublisher.publish(
      business_id: business_id,
      event: "subscription_expiry",
      data: {
        notification_id: notification.id,
        stage: "renewed",
        end_date: end_date.iso8601,
        plan_name: plan.name
      }
    )

    # WhatsApp (if plan includes it)
    owner = business.owner
    if business.current_plan&.whatsapp_notifications? && owner.phone.present?
      Notifications::WhatsAppChannel.deliver(
        recipient: owner,
        template: :subscription_renewed,
        data: {
          business_name: business.name,
          plan_name: plan.name,
          end_date: end_date.strftime("%d/%m/%Y")
        }
      )
    end

    # Activity log
    ActivityLog.log(
      business: business,
      action: "subscription_renewed",
      description: "Suscripción renovada — Plan #{plan.name} hasta #{end_date.strftime('%d/%m/%Y')}",
      actor_type: "system",
      resource: self
    )
  end
end
