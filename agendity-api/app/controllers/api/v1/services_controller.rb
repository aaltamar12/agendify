# frozen_string_literal: true

module Api
  module V1
    # Full CRUD for services scoped to the current business.
    # SRP: Only handles HTTP concerns for service resources.
    class ServicesController < BaseController
      before_action :set_service, only: %i[show update destroy]

      # GET /api/v1/services
      def index
        services = current_business.services
        render_success(ServiceSerializer.render_as_hash(services))
      end

      # GET /api/v1/services/:id
      def show
        render_success(ServiceSerializer.render_as_hash(@service))
      end

      # POST /api/v1/services
      def create
        unless current_business.can_create_service?
          return render_error(
            "Has alcanzado el límite de servicios de tu plan. Mejora tu plan para crear más.",
            status: :forbidden
          )
        end

        service = current_business.services.build(service_params)
        authorize service

        if service.save
          render_success(ServiceSerializer.render_as_hash(service), status: :created)
        else
          render_error(
            service.errors.full_messages.to_sentence,
            status: :unprocessable_entity,
            details: service.errors.messages
          )
        end
      end

      # PATCH /api/v1/services/:id
      def update
        authorize @service

        if @service.update(service_params)
          render_success(ServiceSerializer.render_as_hash(@service))
        else
          render_error(
            @service.errors.full_messages.to_sentence,
            status: :unprocessable_entity,
            details: @service.errors.messages
          )
        end
      end

      # DELETE /api/v1/services/:id
      def destroy
        authorize @service
        @service.update!(active: false)
        render_success({ message: "Servicio desactivado exitosamente" })
      end

      # GET /api/v1/services/categories
      def categories
        cats = current_business.services
                               .where.not(category: [nil, ""])
                               .distinct
                               .pluck(:category)
                               .sort
        render_success(cats)
      end

      # PATCH /api/v1/services/rename_category
      def rename_category
        old_name = params[:old_name]
        new_name = params[:new_name]
        unless old_name.present? && new_name.present?
          return render_error("Nombre requerido", status: :unprocessable_entity)
        end

        updated = current_business.services.where(category: old_name).update_all(category: new_name)
        render_success({ updated: updated, new_name: new_name })
      end

      # DELETE /api/v1/services/delete_category
      def delete_category
        name = params[:name]
        unless name.present?
          return render_error("Nombre requerido", status: :unprocessable_entity)
        end

        updated = current_business.services.where(category: name).update_all(category: nil)
        render_success({ updated: updated })
      end

      private

      def set_service
        @service = current_business.services.find(params[:id])
      end

      def service_params
        params.require(:service).permit(:name, :description, :price, :duration_minutes, :active, :category, :image_url)
      end
    end
  end
end
