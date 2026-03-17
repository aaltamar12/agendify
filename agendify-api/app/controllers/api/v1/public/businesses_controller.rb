# frozen_string_literal: true

module Api
  module V1
    module Public
      # Public-facing business profile and availability (no auth required).
      # SRP: Only handles HTTP concerns for public business viewing.
      class BusinessesController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!

        # GET /api/v1/public/businesses/:slug
        def show
          business = Business.find_by!(slug: params[:slug])

          unless business.active?
            return render_error("Este negocio no está disponible en este momento", status: :forbidden)
          end

          render_success({
            business: BusinessSerializer.render_as_hash(business, view: :public),
            services: ServiceSerializer.render_as_hash(business.services.where(active: true)),
            employees: EmployeeSerializer.render_as_hash(business.employees.where(active: true), view: :minimal),
            business_hours: BusinessHourSerializer.render_as_hash(business.business_hours.order(:day_of_week)),
            reviews: ReviewSerializer.render_as_hash(business.reviews.order(created_at: :desc).limit(10)),
            average_rating: business.rating_average.to_f,
            total_reviews: business.total_reviews
          })
        end

        # GET /api/v1/public/businesses/:slug/availability
        def availability
          business = Business.find_by!(slug: params[:slug])

          unless business.active?
            return render_error("Este negocio no está disponible en este momento", status: :forbidden)
          end

          result = Bookings::AvailabilityService.call(
            business: business,
            date: params[:date],
            service_id: params[:service_id],
            employee_id: params[:employee_id]
          )

          if result.success?
            render_success(result.data)
          else
            render_error(result.error, status: :unprocessable_entity, details: result.details)
          end
        end
      end
    end
  end
end
