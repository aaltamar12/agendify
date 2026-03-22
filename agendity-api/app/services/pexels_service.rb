# frozen_string_literal: true

# Wrapper for the Pexels API to search free stock photos.
class PexelsService
  BASE_URL = "https://api.pexels.com/v1"

  def self.search(query:, per_page: 15, page: 1)
    api_key = ENV["PEXELS_API_KEY"]
    return [] if api_key.blank?

    uri = URI("#{BASE_URL}/search?query=#{ERB::Util.url_encode(query)}&per_page=#{per_page}&page=#{page}&orientation=landscape")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = api_key

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end

    return [] unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    (data["photos"] || []).map do |photo|
      {
        id: photo["id"],
        url_small: photo.dig("src", "medium"),
        url_medium: photo.dig("src", "large"),
        url_large: photo.dig("src", "original"),
        photographer: photo["photographer"],
        alt: photo["alt"]
      }
    end
  rescue StandardError => e
    Rails.logger.error("PexelsService error: #{e.message}")
    []
  end
end
