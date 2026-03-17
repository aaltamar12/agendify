# frozen_string_literal: true

# Authorization policy for Customer resources.
class CustomerPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    belongs_to_user_business?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(business_id: user.businesses.select(:id))
    end
  end

  private

  def belongs_to_user_business?
    user.businesses.exists?(id: record.business_id)
  end
end
