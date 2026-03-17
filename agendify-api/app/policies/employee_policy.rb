# frozen_string_literal: true

# Authorization policy for Employee resources.
class EmployeePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    belongs_to_user_business?
  end

  def create?
    user_has_business?
  end

  def update?
    belongs_to_user_business?
  end

  def destroy?
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

  def user_has_business?
    user.businesses.exists?
  end
end
