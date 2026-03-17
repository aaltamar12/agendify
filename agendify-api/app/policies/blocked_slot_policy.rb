# frozen_string_literal: true

# Authorization policy for BlockedSlot resources.
class BlockedSlotPolicy < ApplicationPolicy
  def index?
    user_has_business?
  end

  def create?
    user_has_business? && belongs_to_user_business?
  end

  def destroy?
    user_has_business? && belongs_to_user_business?
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

  def user_has_business?
    user.businesses.exists?
  end
end
