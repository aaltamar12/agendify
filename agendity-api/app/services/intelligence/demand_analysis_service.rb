# frozen_string_literal: true

module Intelligence
  # Analyzes historical appointment data to detect demand patterns
  # and generate dynamic pricing suggestions. Uses pure SQL queries.
  class DemandAnalysisService < BaseService
    HIGH_DEMAND_THRESHOLD = 0.7  # 70% occupancy = high demand
    WEEKEND_DIFF_THRESHOLD = 1.3 # 30% more on weekends

    def initialize(business:)
      @business = business
    end

    def call
      suggestions = []
      suggestions += analyze_monthly_patterns
      suggestions += analyze_day_of_week_patterns
      suggestions += analyze_seasonal_patterns
      suggestions = filter_existing(suggestions)

      created = suggestions.map { |s| create_suggestion(s) }
      success(created)
    end

    private

    def analyze_monthly_patterns
      monthly_data = @business.appointments
        .where("appointment_date >= ?", 12.months.ago)
        .where.not(status: :cancelled)
        .group("EXTRACT(MONTH FROM appointment_date)")
        .count

      capacity = estimate_monthly_capacity
      return [] if capacity.zero?

      suggestions = []
      monthly_data.each do |month, count|
        occupancy = count.to_f / capacity
        next unless occupancy >= HIGH_DEMAND_THRESHOLD

        month_int = month.to_i
        month_name = Date::MONTHNAMES[month_int] || "Mes #{month_int}"
        adj = suggested_adjustment(occupancy)

        suggestions << {
          name: "Temporada alta — #{month_name}",
          start_date: Date.new(Date.current.year, month_int, 1),
          end_date: Date.new(Date.current.year, month_int, -1),
          adjustment_mode: :fixed_mode,
          adjustment_value: adj,
          reason: "#{month_name} tuvo #{(occupancy * 100).round(0)}% de ocupacion. " \
                  "Sugerimos aumentar tarifas un #{adj}% para maximizar ingresos.",
          analysis: { month: month_int, occupancy: occupancy.round(2), appointments: count, capacity: capacity }
        }
      end
      suggestions
    end

    def analyze_day_of_week_patterns
      daily_data = @business.appointments
        .where("appointment_date >= ?", 3.months.ago)
        .where.not(status: :cancelled)
        .group("EXTRACT(DOW FROM appointment_date)")
        .count

      weekday_values = daily_data.select { |d, _| (1..5).cover?(d.to_i) }.values
      weekend_values = daily_data.select { |d, _| [0, 6].include?(d.to_i) }.values

      weekday_avg = weekday_values.any? ? weekday_values.sum / 5.0 : 0
      weekend_avg = weekend_values.any? ? weekend_values.sum / 2.0 : 0

      return [] unless weekday_avg > 0 && weekend_avg > weekday_avg * WEEKEND_DIFF_THRESHOLD

      pct_diff = ((weekend_avg / weekday_avg - 1) * 100).round(0)
      adj = [pct_diff / 2, 30].min

      [{
        name: "Premium fin de semana",
        start_date: Date.current,
        end_date: Date.current + 90.days,
        adjustment_mode: :fixed_mode,
        adjustment_value: adj,
        days_of_week: [0, 6],
        reason: "Los fines de semana tienes #{pct_diff}% mas demanda. " \
                "Sugerimos una tarifa premium de +#{adj}% para sabados y domingos.",
        analysis: { weekday_avg: weekday_avg.round(1), weekend_avg: weekend_avg.round(1), pct_diff: pct_diff }
      }]
    end

    def analyze_seasonal_patterns
      dec_count = @business.appointments
        .where("EXTRACT(MONTH FROM appointment_date) = 12")
        .where.not(status: :cancelled)
        .count

      yearly_avg = @business.appointments
        .where("appointment_date >= ?", 12.months.ago)
        .where.not(status: :cancelled)
        .count / 12.0

      return [] unless yearly_avg > 0 && dec_count > yearly_avg * 1.4

      pct_over = ((dec_count / yearly_avg - 1) * 100).round(0)

      [{
        name: "Temporada navidena",
        start_date: Date.new(Date.current.year, 12, 1),
        end_date: Date.new(Date.current.year, 12, 31),
        adjustment_mode: :progressive_asc,
        adjustment_start_value: 10,
        adjustment_end_value: 25,
        reason: "Diciembre historicamente tiene #{pct_over}% mas demanda. " \
                "Sugerimos un incremento progresivo del 10% al 25% a lo largo del mes.",
        analysis: { december_appointments: dec_count, monthly_avg: yearly_avg.round(1), pct_over: pct_over }
      }]
    end

    def suggested_adjustment(occupancy)
      base = ((occupancy - HIGH_DEMAND_THRESHOLD) / (1 - HIGH_DEMAND_THRESHOLD) * 20 + 10).round(0)
      base.clamp(10, 30)
    end

    def estimate_monthly_capacity
      employees_count = @business.employees.active.count
      return 0 if employees_count.zero?
      avg_duration = @business.services.average(:duration_minutes)&.to_f || 30
      hours_per_day = 8
      slots_per_day = (hours_per_day * 60 / avg_duration).floor
      working_days = 26
      employees_count * slots_per_day * working_days
    end

    def filter_existing(suggestions)
      suggestions.reject do |s|
        DynamicPricing.where(business: @business)
          .where(status: [:suggested, :active])
          .where("start_date <= ? AND end_date >= ?", s[:end_date], s[:start_date])
          .exists?
      end
    end

    def create_suggestion(data)
      DynamicPricing.create!(
        business: @business,
        name: data[:name],
        start_date: data[:start_date],
        end_date: data[:end_date],
        price_adjustment_type: :percentage,
        adjustment_mode: data[:adjustment_mode] || :fixed_mode,
        adjustment_value: data[:adjustment_value],
        adjustment_start_value: data[:adjustment_start_value],
        adjustment_end_value: data[:adjustment_end_value],
        days_of_week: data[:days_of_week] || [],
        status: :suggested,
        suggested_by: "system",
        suggestion_reason: data[:reason],
        analysis_data: data[:analysis] || {}
      )
    end
  end
end
