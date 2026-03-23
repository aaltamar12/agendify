# frozen_string_literal: true

module Api
  module V1
    module Public
      # Public directory of active businesses (no auth required).
      # SRP: Only handles HTTP concerns for public business exploration.
      class ExploreController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!

        # GET /api/v1/public/cities
        # Returns distinct cities with active businesses for the city dropdown.
        def cities
          cities = Business.active.establishments
                           .where.not(city: [nil, ""])
                           .group(:city)
                           .order(:city)
                           .pluck(:city, Arel.sql("COUNT(*)"))
                           .map { |city, count| { name: city, count: count } }
          render_success(cities)
        end

        # GET /api/v1/public/explore
        def index
          businesses = Business.where(status: :active).establishments
          if params[:search].present?
            businesses = businesses.where(
              "unaccent(businesses.name) ILIKE unaccent(:q) OR unaccent(businesses.description) ILIKE unaccent(:q)",
              q: "%#{params[:search]}%"
            )
          end
          businesses = businesses.where(city: params[:city]) if params[:city].present?
          businesses = businesses.where(business_type: params[:type]) if params[:type].present?

          # Order: verified (ai_features) first, then featured, then by rating
          render_paginated(
            businesses
              .left_joins(subscriptions: :plan)
              .order(
                Arel.sql("COALESCE(plans.ai_features, false) DESC"),
                Arel.sql("COALESCE(plans.featured_listing, false) DESC"),
                rating_average: :desc,
                name: :asc
              ),
            BusinessSerializer,
            view: :explore
          )
        end
      end
    end
  end
end
