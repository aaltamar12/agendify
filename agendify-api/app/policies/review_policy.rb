# frozen_string_literal: true

# Authorization policy for Review resources.
class ReviewPolicy < ApplicationPolicy
  def index?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(business_id: user.businesses.select(:id))
    end
  end
end
