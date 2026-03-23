# frozen_string_literal: true

ActiveAdmin.register_page "Send Notification" do
  menu priority: 12, label: "Enviar Notificacion"

  NOTIFICATION_TYPES = %w[new_booking payment_submitted payment_approved booking_cancelled reminder ai_suggestion subscription_expiry].freeze

  content title: "Enviar Notificacion" do
    businesses = Business.order(:name).pluck(:name, :id)

    panel "Enviar notificacion a negocios" do
      render partial: "admin/send_notification_form", locals: { businesses: businesses, notification_types: NOTIFICATION_TYPES }
    end
  end

  page_action :deliver, method: :post do
    target = params[:target] # "all" or "selected"
    business_ids = params[:business_ids] || []
    notification_type = params[:notification_type]
    custom_title = params[:custom_title].presence
    custom_body = params[:custom_body].presence
    link = params[:link].presence

    # Determine which businesses to notify
    businesses = if target == "all"
                   Business.all
                 else
                   Business.where(id: business_ids)
                 end

    if businesses.none?
      redirect_to admin_send_notification_path, alert: "No se seleccionaron negocios."
      return
    end

    # Build notification attributes
    title = custom_title || default_title_for(notification_type)
    body = custom_body || default_body_for(notification_type)

    if title.blank? || notification_type.blank?
      redirect_to admin_send_notification_path, alert: "El titulo y tipo de notificacion son obligatorios."
      return
    end

    count = 0
    businesses.find_each do |business|
      notification = Notification.create!(
        business: business,
        title: title,
        body: body,
        notification_type: notification_type,
        link: link,
        read: false
      )

      # Publish NATS event using notification_type as event name
      # so the frontend EVENT_CONFIG matches and shows browser notification
      Realtime::NatsPublisher.publish(
        business_id: business.id,
        event: notification_type,
        data: {
          notification_id: notification.id,
          customer_name: "Test (Admin)",
          service_name: "Test notification"
        }
      )

      ActivityLog.log(
        business: business,
        action: "admin_notification_sent",
        description: "Notificacion enviada por admin: #{title}",
        actor_type: "admin",
        actor_name: current_admin_user&.email || "SuperAdmin",
        resource: notification,
        metadata: {
          notification_type: notification_type,
          title: title,
          body: body,
          link: link,
          sent_by: current_admin_user&.email
        }
      )

      count += 1
    end

    Rails.logger.info("[SendNotification] Admin #{current_admin_user&.email} sent #{count} notification(s) type=#{notification_type} title=#{title}")
    redirect_to admin_send_notification_path, notice: "#{count} notificacion(es) enviada(s) exitosamente."
  end

  controller do
    private

    def default_title_for(type)
      case type
      when "new_booking" then "Nueva reserva"
      when "payment_submitted" then "Pago enviado"
      when "payment_approved" then "Pago aprobado"
      when "booking_cancelled" then "Reserva cancelada"
      when "reminder" then "Recordatorio"
      when "ai_suggestion" then "Sugerencia de Agendity"
      when "subscription_expiry" then "Tu suscripción está por vencer"
      else "Notificacion"
      end
    end

    def default_body_for(type)
      case type
      when "new_booking" then "Tienes una nueva reserva pendiente."
      when "payment_submitted" then "Se ha enviado un nuevo pago para revision."
      when "payment_approved" then "Un pago ha sido aprobado."
      when "booking_cancelled" then "Una reserva ha sido cancelada."
      when "reminder" then "Este es un recordatorio del equipo de Agendity."
      when "ai_suggestion" then "Tenemos una sugerencia para mejorar tu negocio."
      when "subscription_expiry" then "Tu plan está próximo a vencer. Renueva para mantener acceso a todas las funcionalidades."
      else ""
      end
    end
  end
end
