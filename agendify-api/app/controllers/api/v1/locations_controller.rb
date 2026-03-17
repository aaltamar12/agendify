# frozen_string_literal: true

module Api
  module V1
    # Provides geographic data (countries, states, cities) for location selectors.
    # Uses the city-state gem (MaxMind database). No authentication required.
    class LocationsController < ApiController
      # GET /api/v1/locations/countries
      def countries
        data = ::CS.countries.map { |code, name| { code: code.to_s, name: name } }
                .sort_by { |c| c[:name] }
        render json: { data: data }
      end

      # GET /api/v1/locations/states?country=CO
      def states
        country = params[:country]&.upcase&.to_sym
        return render json: { data: [] } unless country

        data = ::CS.states(country).map { |code, name| { code: code.to_s, name: clean_state_name(name) } }
                  .sort_by { |s| s[:name] }
        render json: { data: data }
      end

      # GET /api/v1/locations/cities?country=CO&state=ATL
      def cities
        country = params[:country]&.upcase&.to_sym
        state = params[:state]&.upcase&.to_sym
        return render json: { data: [] } unless country && state

        data = (::CS.cities(state, country) || []).sort.map { |name| { name: name } }
        render json: { data: data }
      end

      private

      # Remove verbose prefixes from state names (e.g., "Departamento de Bolivar" → "Bolívar")
      def clean_state_name(name)
        name.gsub(/\ADepartamento del?\s+/i, "")
            .gsub(/\s+Department\z/i, "")
      end
    end
  end
end
