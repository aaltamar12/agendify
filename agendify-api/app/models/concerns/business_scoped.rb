# frozen_string_literal: true

# Shared concern for models that belong to a business.
# Adds the association and a convenience scope for filtering.
module BusinessScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :business

    scope :for_business, ->(id) { where(business_id: id) }
  end
end
