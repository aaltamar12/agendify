# frozen_string_literal: true

module Api
  module V1
    # Read-only access to customers scoped to the current business.
    # SRP: Only handles HTTP concerns for customer listing and detail.
    class CustomersController < BaseController
      # GET /api/v1/customers
      def index
        customers = current_business.customers
        customers = customers.where(
          "name ILIKE :q OR email ILIKE :q OR phone ILIKE :q",
          q: "%#{params[:search]}%"
        ) if params[:search].present?

        render_paginated(customers, CustomerSerializer)
      end

      # GET /api/v1/customers/:id
      def show
        customer = current_business.customers.find(params[:id])
        render_success(CustomerSerializer.render_as_hash(customer, view: :with_appointments))
      end

      # POST /api/v1/customers/:id/send_birthday_greeting
      def send_birthday_greeting
        customer = current_business.customers.find(params[:id])

        unless current_business.has_feature?(:ai_features)
          return render_error("Disponible solo en Plan Inteligente", status: :forbidden)
        end

        Notifications::MultiChannelService.call(
          business: current_business,
          recipient: customer,
          template: :birthday_greeting_manual,
          data: {
            customer_name: customer.name,
            business_name: current_business.name,
            booking_url: "#{SiteConfig.get('app_url')}/#{current_business.slug}"
          }
        )

        render_success({ message: "Saludo de cumpleaños enviado" })
      end
    end
  end
end
