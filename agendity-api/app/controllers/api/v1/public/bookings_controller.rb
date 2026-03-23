# frozen_string_literal: true

module Api
  module V1
    module Public
      # Public booking creation (no auth required).
      # SRP: Only handles HTTP concerns for public appointment booking.
      class BookingsController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!

        # POST /api/v1/public/businesses/:slug/book
        def create
          result = Bookings::CreateBookingService.call(
            slug: params[:slug], params: booking_params, lock_token: params[:lock_token]
          )

          if result.success?
            appointment = result.data[:appointment]
            penalty_applied = result.data[:penalty_applied] || 0
            response = {
              appointment: AppointmentSerializer.render_as_hash(appointment, view: :detailed),
              ticket_code: appointment.ticket_code,
              business: BusinessSerializer.render_as_hash(appointment.business, view: :with_payment)
            }
            response[:penalty_applied] = penalty_applied if penalty_applied.positive?
            render_success(response, status: :created)
          else
            render_error(result.error, status: :unprocessable_entity, details: result.details)
          end
        end

        # POST /api/v1/public/:slug/lock_slot
        # Temporarily locks a slot while the user fills the booking form (5 min).
        def lock_slot
          token = Bookings::SlotLockService.lock(
            business_id: find_business_id,
            employee_id: params[:employee_id],
            date:        params[:date],
            time:        params[:time]
          )

          if token
            render_success({ lock_token: token, expires_in: Bookings::SlotLockService::LOCK_TTL })
          else
            render_error(
              "Este horario está siendo reservado por otra persona. Intenta con otro horario.",
              status: :conflict
            )
          end
        end

        # POST /api/v1/public/:slug/unlock_slot
        # Releases a temporary slot lock (e.g., user goes back or cancels).
        def unlock_slot
          Bookings::SlotLockService.unlock(
            business_id: find_business_id,
            employee_id: params[:employee_id],
            date:        params[:date],
            time:        params[:time],
            token:       params[:lock_token]
          )

          render_success({ released: true })
        end

        # GET /api/v1/public/:slug/check_slot
        # Re-validates slot availability right before the user confirms.
        def check_slot
          business = Business.friendly.find_by!(slug: params[:slug])

          service = business.services.find_by(id: params[:service_id])
          return render_error("Servicio no encontrado.", status: :not_found) unless service

          result = Bookings::AvailabilityService.call(
            business:    business,
            service_id:  service.id,
            date:        params[:date],
            employee_id: params[:employee_id]
          )

          unless result.success?
            return render_success({ available: false, reason: result.error })
          end

          slot = result.data.find { |s| s[:time] == params[:time] }
          available = slot.present? && slot[:available]

          render_success({ available: available })
        end

        # GET /api/v1/public/:slug/validate_code?code=X
        # Validates a discount code for a business and returns its details.
        def validate_code
          business = Business.friendly.find_by!(slug: params[:slug])
          code = business.discount_codes.available.find_by(code: params[:code].to_s.upcase)

          if code
            render_success({
              valid: true,
              discount_type: code.discount_type,
              discount_value: code.discount_value,
              name: code.name
            })
          else
            render_success({ valid: false })
          end
        end

        # GET /api/v1/public/customer_lookup?email=...&slug=...
        # Looks up a customer by email within a business so the booking form can pre-fill data.
        def customer_lookup
          business = Business.friendly.find_by!(slug: params[:slug])
          customer = business.customers.find_by("LOWER(email) = ?", params[:email].to_s.downcase.strip)

          if customer
            credit_account = CreditAccount.find_by(customer: customer, business: business)
            render_success({
              name: customer.name,
              email: customer.email,
              phone: customer.phone,
              credit_balance: credit_account&.balance.to_f || 0
            })
          else
            render_error("No encontramos una reserva anterior con ese correo.", status: :not_found)
          end
        end

        private

        def find_business_id
          Business.friendly.find_by!(slug: params[:slug]).id
        end

        def booking_params
          # Support both nested { booking: { ... } } and flat params
          raw = if params.key?(:booking)
                  params.require(:booking).permit(
                    :service_id, :employee_id, :date, :appointment_date, :start_time, :notes,
                    :customer_name, :customer_email, :customer_phone, :customer_birth_date,
                    :apply_credits, :discount_code,
                    customer: %i[name email phone birth_date],
                    additional_service_ids: []
                  )
                else
                  params.permit(
                    :service_id, :employee_id, :date, :appointment_date, :start_time, :notes,
                    :customer_name, :customer_email, :customer_phone, :customer_birth_date,
                    :apply_credits, :discount_code,
                    customer: %i[name email phone birth_date],
                    additional_service_ids: []
                  )
                end

          # Flatten nested customer fields
          if raw[:customer].present?
            raw[:customer_name]  = raw[:customer][:name]
            raw[:customer_email] = raw[:customer][:email]
            raw[:customer_phone] = raw[:customer][:phone]
            raw[:customer_birth_date] = raw[:customer][:birth_date] if raw[:customer][:birth_date].present?
            raw.delete(:customer)
          end

          # Normalize date field: accept either "date" or "appointment_date"
          if raw.key?(:date) && !raw.key?(:appointment_date)
            raw[:appointment_date] = raw.delete(:date)
          elsif raw.key?(:date)
            raw.delete(:date)
          end

          raw
        end
      end
    end
  end
end
