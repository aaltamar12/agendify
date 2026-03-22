# frozen_string_literal: true

ActiveAdmin.register_page "Send Notification" do
  menu priority: 12, label: "Enviar Notificacion"

  NOTIFICATION_TYPES = %w[new_booking payment_submitted payment_approved booking_cancelled reminder ai_suggestion].freeze

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

      # Publish NATS event for real-time push
      Realtime::NatsPublisher.publish(
        business_id: business.id,
        event: "notification.created",
        data: {
          id: notification.id,
          title: notification.title,
          body: notification.body,
          notification_type: notification.notification_type,
          link: notification.link,
          read: false,
          created_at: notification.created_at.iso8601
        }
      )

      count += 1
    end

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
      else ""
      end
    end
  end
end
