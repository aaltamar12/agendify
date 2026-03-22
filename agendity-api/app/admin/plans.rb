# frozen_string_literal: true

ActiveAdmin.register Plan do
  permit_params :name, :price_monthly, :price_monthly_usd, :max_employees, :max_services,
                :max_reservations_month, :max_customers,
                :ai_features, :ticket_digital, :advanced_reports,
                :brand_customization, :featured_listing, :priority_support,
                :cashback_enabled, :cashback_percentage

  # -- Index --
  index do
    selectable_column
    id_column
    column :name
    column("Price (COP)") { |p| "$#{p.price_monthly.to_f.round(0)} COP" }
    column("Price (USD)") { |p| p.price_monthly_usd ? "$#{p.price_monthly_usd} USD" : "—" }
    column :max_employees
    column :max_services
    column :max_reservations_month
    column :ai_features
    column :ticket_digital
    column :advanced_reports
    column :cashback_enabled
    column("Cashback %") { |p| p.cashback_percentage ? "#{p.cashback_percentage}%" : "—" }
    actions
  end

  # -- Filters --
  filter :name
  filter :ai_features
  filter :ticket_digital

  # -- Form --
  form do |f|
    f.inputs "Plan Details" do
      f.input :name
      f.input :price_monthly, label: "Price Monthly (COP)"
      f.input :price_monthly_usd, label: "Price Monthly (USD)"
      f.input :max_employees
      f.input :max_services
      f.input :max_reservations_month
      f.input :max_customers
    end
    f.inputs "Features" do
      f.input :ai_features
      f.input :ticket_digital
      f.input :advanced_reports
      f.input :brand_customization
      f.input :featured_listing
      f.input :priority_support
    end
    f.inputs "Cashback" do
      f.input :cashback_enabled, label: "Cashback Enabled"
      f.input :cashback_percentage, label: "Cashback Percentage (%)"
    end
    f.actions
  end
end
