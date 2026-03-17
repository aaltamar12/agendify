# frozen_string_literal: true

# Provides plan limit checks for a Business.
# Included in Business to enforce subscription plan restrictions
# on employees, services, and feature access.
module PlanEnforcement
  extend ActiveSupport::Concern

  included do
    # Returns the plan from the current active subscription, or nil.
    def current_plan
      subscriptions.current.order(end_date: :desc).first&.plan
    end

    # Can the business create another employee within plan limits?
    def can_create_employee?
      plan = current_plan
      return true unless plan&.max_employees # nil = unlimited
      employees.active.count < plan.max_employees
    end

    # Can the business create another service within plan limits?
    def can_create_service?
      plan = current_plan
      return true unless plan&.max_services # nil = unlimited
      services.active.count < plan.max_services
    end

    # Does the current plan include the given boolean feature?
    # No plan (trial) grants all features.
    def has_feature?(feature)
      plan = current_plan
      return true unless plan # No plan = trial = all features
      plan.respond_to?(feature) ? plan.public_send(feature) : false
    end
  end
end
