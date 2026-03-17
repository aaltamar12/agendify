# frozen_string_literal: true

module Api
  module V1
    # Manages blocked time slots for employees within the current business.
    # SRP: Only handles HTTP concerns for blocked slot resources.
    class BlockedSlotsController < BaseController
      # GET /api/v1/blocked_slots
      def index
        slots = current_business.blocked_slots
        slots = slots.where(date: params[:date]) if params[:date].present?
        slots = slots.where(employee_id: params[:employee_id]) if params[:employee_id].present?

        render_paginated(slots, BlockedSlotSerializer)
      end

      # POST /api/v1/blocked_slots
      def create
        slot = current_business.blocked_slots.build(blocked_slot_params)
        authorize slot

        if slot.save
          render_success(BlockedSlotSerializer.render_as_hash(slot), status: :created)
        else
          render_error(
            slot.errors.full_messages.to_sentence,
            status: :unprocessable_entity,
            details: slot.errors.messages
          )
        end
      end

      # DELETE /api/v1/blocked_slots/:id
      def destroy
        slot = current_business.blocked_slots.find(params[:id])
        authorize slot
        slot.destroy!
        render_success({ message: "Bloqueo de horario eliminado exitosamente" })
      end

      private

      def blocked_slot_params
        params.permit(:employee_id, :date, :start_time, :end_time, :reason)
      end
    end
  end
end
