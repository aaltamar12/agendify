# frozen_string_literal: true

module Bookings
  # Public-facing booking flow (no authentication required).
  # Finds the business by its slug and delegates to the
  # appointment creation service.
  class CreateBookingService < BaseService
    def initialize(slug:, params:, lock_token: nil)
      @slug       = slug
      @params     = params
      @lock_token = lock_token
    end

    def call
      business = Business.friendly.find_by(slug: @slug)
      return failure("Business not found") unless business
      return failure("Business is not active") unless business.active?

      result = Appointments::CreateAppointmentService.call(
        business: business, params: @params, lock_token: @lock_token
      )
      return result if result.failure?

      appointment = result.data[:appointment]
      penalty_applied = result.data[:penalty_applied]

      ::SendNewBookingNotificationJob.perform_later(appointment.id)

      success({ appointment: appointment, business: business, penalty_applied: penalty_applied })
    end
  end
end
