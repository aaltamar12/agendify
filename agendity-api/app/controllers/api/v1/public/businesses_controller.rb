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

        # GET /api/v1/public/:slug/price_preview?service_id=X&date=Y
        def price_preview
          business = Business.find_by!(slug: params[:slug])
          service = business.services.find(params[:service_id])
          date = Date.parse(params[:date]) rescue Date.current

          pricing = business.dynamic_pricings
            .for_date(date)
            .where("service_id = ? OR service_id IS NULL", service.id)
            .order(Arel.sql("service_id IS NOT NULL DESC"))
            .to_a
            .find { |p| p.applies_on_day?(date) }

          base_price = service.price.to_f

          if pricing
            adjusted = pricing.apply_to_price(base_price, date)
            pct = pricing.effective_adjustment(date)
            render_success({
              base_price: base_price,
              adjusted_price: adjusted,
              adjustment_pct: pct.round(1),
              dynamic_pricing_name: pricing.name,
              is_discount: pct < 0,
              has_dynamic_pricing: true
            })
          else
            render_success({
              base_price: base_price,
              adjusted_price: base_price,
              adjustment_pct: 0,
              dynamic_pricing_name: nil,
              is_discount: false,
              has_dynamic_pricing: false
            })
          end
        end

        # GET /api/v1/public/:slug/price_calendar?service_id=X&from=Y&days=14
        def price_calendar
          business = Business.find_by!(slug: params[:slug])
          service = business.services.find(params[:service_id])
          from_date = Date.parse(params[:from] || Date.current.to_s)
          days = (params[:days] || 14).to_i.clamp(1, 30)
          base_price = service.price.to_f

          calendar = (0...days).map do |i|
            date = from_date + i.days
            bh = business.business_hours.find_by(day_of_week: date.wday)
            closed = bh.nil? || bh.closed?

            # Find the pricing that actually applies to this day (checks days_of_week)
            pricing = business.dynamic_pricings
              .for_date(date)
              .where("service_id = ? OR service_id IS NULL", service.id)
              .order(Arel.sql("service_id IS NOT NULL DESC"))
              .to_a
              .find { |p| p.applies_on_day?(date) }

            adjusted = base_price
            pct = 0.0
            has_pricing = false

            if !closed && pricing
              adjusted = pricing.apply_to_price(base_price, date)
              pct = pricing.effective_adjustment(date)
              has_pricing = true
            end

            {
              date: date.to_s,
              day_name: (I18n.l(date, format: "%a") rescue date.strftime("%a")),
              closed: closed,
              base_price: base_price,
              adjusted_price: adjusted.round(2),
              adjustment_pct: pct.round(1),
              has_dynamic_pricing: has_pricing,
              is_discount: pct < 0
            }
          end

          render_success(calendar)
        end
      end
    end
  end
end
