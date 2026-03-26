# frozen_string_literal: true

module Api
  module V1
    module Public
      # Public review creation (no auth required).
      # Allows customers to submit a rating from the dedicated rating page.
      class ReviewsController < Api::V1::BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!
        skip_before_action :render_empty_for_admin_without_business!

        # GET /api/v1/public/:slug/rate?appointment=ID
        # Returns appointment data needed to render the rating page.
        def show
          business = Business.find_by!(slug: params[:slug])
          appointment = business.appointments.includes(:service, :employee, :customer).find(params[:appointment])

          existing_review = Review.find_by(appointment_id: appointment.id)

          render_success({
            appointment: {
              id: appointment.id,
              service_name: appointment.service.name,
              employee_name: appointment.employee&.name,
              appointment_date: appointment.appointment_date,
              customer_name: appointment.customer&.name
            },
            business_name: business.name,
            business_logo_url: business.logo_url,
            already_reviewed: existing_review.present?
          })
        end

        # POST /api/v1/public/:slug/reviews
        # Creates a business review (rating) and optionally an employee review (employee_rating)
        def create
          business = Business.find_by!(slug: params[:slug])
          appointment = business.appointments.find(params[:appointment_id])

          # Prevent duplicate reviews for the same appointment
          existing = Review.find_by(appointment_id: appointment.id, employee_id: nil)
          if existing
            return render_error("Ya calificaste esta cita.", status: :unprocessable_entity)
          end

          customer_name = params[:customer_name] || appointment.customer&.name

          # Business review (always)
          review = business.reviews.create!(
            appointment_id: appointment.id,
            customer_id: appointment.customer_id,
            employee_id: nil,
            customer_name: customer_name,
            rating: params[:rating],
            comment: params[:comment]
          )

          # Employee review (if employee_rating provided and appointment has employee)
          if params[:employee_rating].present? && appointment.employee_id.present?
            business.reviews.create!(
              appointment_id: appointment.id,
              customer_id: appointment.customer_id,
              employee_id: appointment.employee_id,
              customer_name: customer_name,
              rating: params[:employee_rating],
              comment: nil
            )
          end

          render_success({ review: ReviewSerializer.render_as_hash(review) }, status: :created)
        rescue ActiveRecord::RecordInvalid => e
          render_error(e.message, status: :unprocessable_entity)
        end
      end
    end
  end
end
