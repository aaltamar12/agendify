# frozen_string_literal: true

# Provides reusable attachment validation methods for file size and content type.
# Usage in models:
#   include AttachmentValidations
#   validate_attachment :logo, max_size: 5.megabytes, content_types: ALLOWED_IMAGE_TYPES
module AttachmentValidations
  extend ActiveSupport::Concern

  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze

  class_methods do
    def validate_attachment(name, max_size:, content_types: ALLOWED_IMAGE_TYPES)
      validate do |record|
        attachment = record.send(name)
        next unless attachment.attached? && attachment.blob.present?

        blob = attachment.blob

        unless content_types.include?(blob.content_type)
          record.errors.add(name, "must be #{content_types.map { |t| t.split('/').last.upcase }.join(', ')}")
        end

        if blob.byte_size > max_size
          max_mb = (max_size / 1.megabyte.to_f).round(0).to_i
          record.errors.add(name, "must be less than #{max_mb}MB (received #{(blob.byte_size / 1.megabyte.to_f).round(1)}MB)")
        end
      end
    end
  end
end
