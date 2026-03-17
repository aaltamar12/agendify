# frozen_string_literal: true

# Authorization policy for Business resources.
class BusinessPolicy < ApplicationPolicy
  def show?
    owner?
  end

  def update?
    owner? || user.admin?
  end

  def onboarding?
    owner?
  end

  private

  def owner?
    record.owner_id == user.id
  end
end
