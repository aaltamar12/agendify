# frozen_string_literal: true

module Api
  module V1
    module Public
      # Public ad banner endpoints (no auth required).
      # Serves banners for public booking pages and tracks impressions/clicks.
      class AdBannersController < BaseController
        skip_before_action :authenticate_user!
        skip_before_action :require_business!

        # GET /api/v1/public/ad_banners?placement=booking_summary
        # Returns one active banner for the given placement (highest priority, within date range).
        def index
          banner = AdBanner
            .active
            .for_placement(params[:placement])
            .current
            .order(priority: :desc)
            .first

          if banner
            render_success({
              id: banner.id,
              name: banner.name,
              placement: banner.placement,
              image_url: banner.display_image_url,
              link_url: banner.link_url,
              alt_text: banner.alt_text
            })
          else
            render_success(nil)
          end
        end

        # POST /api/v1/public/ad_banners/:id/impression
        def impression
          banner = AdBanner.find(params[:id])
          banner.increment!(:impressions_count)
          render_success({ tracked: true })
        end

        # POST /api/v1/public/ad_banners/:id/click
        def click
          banner = AdBanner.find(params[:id])
          banner.increment!(:clicks_count)
          render_success({ tracked: true })
        end
      end
    end
  end
end
