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
    end
  end
end
