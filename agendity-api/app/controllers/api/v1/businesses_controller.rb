# frozen_string_literal: true

module Api
  module V1
    # Manages the current user's business (singular resource).
    # SRP: Only handles HTTP concerns for business management.
    class BusinessesController < BaseController
      skip_before_action :render_empty_for_admin_without_business!, only: :show

      # GET /api/v1/business
      def show
        return render_success(nil) if admin_without_business?

        render_success(BusinessSerializer.render_as_hash(current_business))
      end

      # PATCH /api/v1/business
      def update
        if (business_params.key?(:primary_color) || business_params.key?(:secondary_color)) &&
           !current_business.has_feature?(:brand_customization)
          return render_error(
            "La personalización de marca requiere Plan Profesional o superior.",
            status: :forbidden
          )
        end

        result = Businesses::UpdateService.call(business: current_business, params: business_params)

        if result.success?
          render_success(BusinessSerializer.render_as_hash(result.data))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      # POST /api/v1/business/upload_logo
      def upload_logo
        unless params[:logo].present?
          return render_error("No se envió ningún archivo", status: :unprocessable_entity)
        end

        current_business.logo.attach(params[:logo])

        if current_business.logo.attached?
          render_success(BusinessSerializer.render_as_hash(current_business))
        else
          render_error("Error al subir el logo", status: :unprocessable_entity)
        end
      end

      # POST /api/v1/business/upload_cover
      def upload_cover
        unless params[:cover].present?
          return render_error("No se envió ningún archivo", status: :unprocessable_entity)
        end

        current_business.cover_image.attach(params[:cover])
        current_business.update!(cover_source: "upload")

        if current_business.cover_image.attached?
          render_success(BusinessSerializer.render_as_hash(current_business))
        else
          render_error("Error al subir la portada", status: :unprocessable_entity)
        end
      end

      # GET /api/v1/business/cover_gallery
      def cover_gallery
        query = params[:query] || current_business.business_type || "barbershop"
        page = (params[:page] || 1).to_i
        photos = PexelsService.search(query: query, per_page: 15, page: page)
        render_success(photos)
      end

      # POST /api/v1/business/select_cover
      def select_cover
        url = params[:url]
        return render_error("URL requerida", status: :unprocessable_entity) if url.blank?

        # Download from Pexels and attach
        require "open-uri"
        file = URI.parse(url).open
        filename = "cover_#{current_business.id}_#{Time.current.to_i}.jpg"
        current_business.cover_image.attach(io: file, filename: filename, content_type: file.content_type || "image/jpeg")
        current_business.update!(cover_source: "pexels")

        render_success(BusinessSerializer.render_as_hash(current_business))
      rescue OpenURI::HTTPError, URI::InvalidURIError => e
        render_error("Error al descargar la imagen: #{e.message}", status: :unprocessable_entity)
      end

      # POST /api/v1/business/onboarding
      def onboarding
        result = Businesses::CompleteOnboardingService.call(business: current_business, params: onboarding_params)

        if result.success?
          render_success(BusinessSerializer.render_as_hash(result.data))
        else
          render_error(result.error, status: :unprocessable_entity, details: result.details)
        end
      end

      private

      def business_params
        permitted = params.require(:business).permit(
          :name, :business_type, :description, :phone, :email,
          :address, :city, :state, :country, :latitude, :longitude,
          :logo_url, :cover_url, :instagram_url, :facebook_url, :website_url,
          :google_maps_url, :timezone, :currency,
          :nequi_phone, :daviplata_phone, :bancolombia_account,
          :primary_color, :secondary_color,
          :cancellation_policy_pct, :cancellation_deadline_hours,
          :lunch_start_time, :lunch_end_time, :lunch_enabled,
          :slot_interval_minutes, :gap_between_appointments_minutes,
          :cashback_enabled, :cashback_percentage, :cancellation_refund_as_credit
        )
        # Map frontend cover_url to DB column cover_image_url
        if permitted.key?(:cover_url)
          permitted[:cover_image_url] = permitted.delete(:cover_url)
        end
        permitted
      end

      def onboarding_params
        params.permit(
          :name, :business_type, :phone, :address, :city, :state, :country,
          services: %i[name duration_minutes price],
          employees: %i[name phone],
          business_hours: %i[day_of_week open_time close_time closed]
        )
      end
    end
  end
end
