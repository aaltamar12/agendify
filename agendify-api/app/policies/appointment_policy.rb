# frozen_string_literal: true

# Authorization policy for Appointment resources.
class AppointmentPolicy < ApplicationPolicy
  def index?
    belongs_to_user_business?
  end

  def show?
    belongs_to_user_business?
  end

  def create?
    belongs_to_user_business?
  end

  def update?
    belongs_to_user_business?
  end

  def confirm?
    belongs_to_user_business?
  end

  def checkin?
    belongs_to_user_business?
  end

  def cancel?
    belongs_to_user_business?
  end

  def complete?
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
