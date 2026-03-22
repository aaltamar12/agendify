# frozen_string_literal: true

class DynamicPricing < ApplicationRecord
  belongs_to :business
  belongs_to :service, optional: true

  enum :price_adjustment_type, { percentage: 0, fixed: 1 }
  enum :adjustment_mode, { fixed_mode: 0, progressive_asc: 1, progressive_desc: 2 }
  enum :status, { suggested: 0, active: 1, rejected: 2, expired: 3 }

  validates :name, :start_date, :end_date, presence: true
  validate :end_date_after_start_date
  validate :adjustment_values_present
  validate :no_overlapping_active_pricing

  scope :currently_active, -> { active.where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :for_date, ->(date) { active.where("start_date <= ? AND end_date >= ?", date, date) }
  scope :pending_suggestions, -> { suggested.where("created_at > ?", 30.days.ago) }

  # Calculate the adjusted price for a given date
  def apply_to_price(base_price, date = Date.current)
    return base_price unless applies_on_day?(date)

    adjustment = effective_adjustment(date)

    case price_adjustment_type
    when "percentage"
      (base_price + (base_price * adjustment / 100)).round(2)
    when "fixed"
      (base_price + adjustment).round(2)
    end
  end

  # Check if this pricing applies on a specific day of the week
  def applies_on_day?(date)
    return true if days_of_week.blank? || days_of_week.empty?
    days_of_week.include?(date.wday)
  end

  # Get the effective adjustment value for a specific date (handles progressive)
  def effective_adjustment(date)
    case adjustment_mode
    when "fixed_mode"
      adjustment_value || 0
    when "progressive_asc"
      interpolate(date, adjustment_start_value, adjustment_end_value)
    when "progressive_desc"
      interpolate(date, adjustment_start_value, adjustment_end_value)
    else
      adjustment_value || 0
    end
  end

  private

  def interpolate(date, from_value, to_value)
    return from_value || 0 if start_date == end_date

    total_days = (end_date - start_date).to_f
    elapsed = (date - start_date).to_f.clamp(0, total_days)
    progress = elapsed / total_days

    from = from_value || 0
    to = to_value || 0
    (from + (to - from) * progress).round(2)
  end

  def end_date_after_start_date
    return unless end_date && start_date
    errors.add(:end_date, "debe ser posterior a la fecha de inicio") if end_date < start_date
  end

  def adjustment_values_present
    if fixed_mode?
      errors.add(:adjustment_value, "es requerido") if adjustment_value.blank?
    else
      errors.add(:adjustment_start_value, "es requerido") if adjustment_start_value.blank?
      errors.add(:adjustment_end_value, "es requerido") if adjustment_end_value.blank?
    end
  end

  def no_overlapping_active_pricing
    return unless active? && business_id
    scope = DynamicPricing.where(business_id: business_id, status: :active)
      .where("start_date <= ? AND end_date >= ?", end_date, start_date)
    scope = scope.where(service_id: service_id) if service_id
    scope = scope.where.not(id: id) if persisted?
    errors.add(:base, "Ya existe una tarifa activa para este periodo") if scope.exists?
  end
end
