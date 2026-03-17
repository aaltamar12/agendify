# frozen_string_literal: true

module Api
  module V1
    # Read-only access to reviews scoped to the current business.
    # SRP: Only handles HTTP concerns for review listing.
    class ReviewsController < BaseController
      # GET /api/v1/reviews
      def index
        reviews = current_business.reviews.order(created_at: :desc)
        render_paginated(reviews, ReviewSerializer)
      end
    end
  end
end
