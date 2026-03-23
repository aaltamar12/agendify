# frozen_string_literal: true

module Api
  module V1
    # Base controller for all authenticated API v1 endpoints.
    # Provides authorization, pagination, and standardized JSON responses.
    #
    # SRP: Handles cross-cutting concerns (auth, error handling, response formatting).
    # OCP: Subclasses extend behavior without modifying this class.
    # LSP: All V1 controllers inherit consistently from this base.
    # DIP: Controllers depend on service abstractions, not concrete implementations.
    class BaseController < ApiController
      include Pundit::Authorization
      include RequestLogging

      before_action :authenticate_user!
      before_action :require_business!
      before_action :render_empty_for_admin_without_business!

      # --- Error handling ---

      rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

      private

      # --- Authentication ---

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        payload = Auth::TokenGenerator.decode(token) if token
        if payload.nil? || JwtDenylist.exists?(jti: payload[:jti])
          render json: { error: "Not authenticated" }, status: :unauthorized
          return
        end
        @current_user = User.find_by(id: payload[:sub])
        render json: { error: "Not authenticated" }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end

      def require_business!
        return if current_user&.admin? && !current_business
          # Admin without business: skip guard but controllers must handle nil current_business
        return if current_business

        render_error("No business associated with this account", status: :forbidden)
      end

      # Returns true if current user is an admin without an associated business
      # (i.e., not impersonating). Controllers use this to return empty data.
      def admin_without_business?
        current_user&.admin? && current_business.nil?
      end

      # Admins without a business (not impersonating) get empty responses
      # instead of 500s from controllers that scope by current_business.
      def render_empty_for_admin_without_business!
        return unless admin_without_business?

        render json: { data: [], meta: { current_page: 1, total_pages: 0, total_count: 0, per_page: 10 } }
      end

      # --- Helpers ---

      # Returns the business associated with the current authenticated user.
      def current_business
        @current_business ||= current_user&.business
      end

      # --- Response helpers ---

      def render_success(data, status: :ok)
        render json: { data: data }, status: status
      end

      def render_error(message, status: :bad_request, details: nil)
        body = { error: message }
        body[:details] = details if details.present?
        render json: body, status: status
      end

      def render_paginated(collection, serializer, view: nil)
        page = (params[:page] || 1).to_i
        per_page = [(params[:per_page] || 10).to_i, 100].min
        pagy = Pagy::Offset.new(count: collection.count, page: page, limit: per_page)
        records = collection.offset(pagy.offset).limit(pagy.limit)
        serializer_opts = view ? { view: view } : {}
        render json: {
          data: serializer.render_as_hash(records, **serializer_opts),
          meta: {
            current_page: pagy.page,
            total_pages: pagy.pages,
            total_count: pagy.count,
            per_page: pagy.limit
          }
        }
      end

      # --- Error handlers ---

      def handle_unauthorized(_exception)
        render_error("Not authorized", status: :forbidden)
      end

      def handle_not_found(_exception)
        render_error("Resource not found", status: :not_found)
      end

      def handle_record_invalid(exception)
        render_error(
          exception.record.errors.full_messages.to_sentence,
          status: :unprocessable_entity,
          details: exception.record.errors.messages
        )
      end

      def handle_pagination_overflow(_exception)
        render_error("Page number out of range", status: :bad_request)
      end
    end
  end
end
