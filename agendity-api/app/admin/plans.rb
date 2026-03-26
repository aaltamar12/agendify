# frozen_string_literal: true

ActiveAdmin.register Plan do
  permit_params :name, :price_monthly, :price_monthly_usd, :max_employees, :max_services,
                :max_reservations_month, :max_customers,
                :ai_features, :ticket_digital, :advanced_reports,
                :brand_customization, :featured_listing, :priority_support,
                :cashback_enabled, :cashback_percentage,
                features: []

  # -- Index --
  index do
    selectable_column
    id_column
    column :name
    column("Price (COP)") { |p| "$#{p.price_monthly.to_f.round(0)} COP" }
    column("Price (USD)") { |p| p.price_monthly_usd ? "$#{p.price_monthly_usd} USD" : "—" }
    column :max_employees
    column :max_services
    column("Features") { |p| p.features&.count || 0 }
    column :ai_features
    column :ticket_digital
    column :cashback_enabled
    actions
  end

  # -- Show --
  show do
    attributes_table do
      row :name
      row("Price (COP)") { |p| "$#{p.price_monthly.to_f.round(0)} COP" }
      row("Price (USD)") { |p| p.price_monthly_usd ? "$#{p.price_monthly_usd} USD" : "—" }
      row :max_employees
      row :max_services
      row :max_reservations_month
      row :max_customers
      row :ai_features
      row :ticket_digital
      row :advanced_reports
      row :brand_customization
      row :featured_listing
      row :priority_support
      row :cashback_enabled
      row("Cashback %") { |p| p.cashback_percentage ? "#{p.cashback_percentage}%" : "—" }
    end
    panel "Features del Plan (visibles al cliente)" do
      if resource.features.present?
        ul do
          resource.features.each { |f| li f }
        end
      else
        para "Sin features configuradas", class: "empty"
      end
    end
  end

  # -- Filters --
  filter :name
  filter :ai_features
  filter :ticket_digital

  # -- Form --
  form do |f|
    trm = SiteConfig.get("trm_rate")&.to_f || 3667
    trm_formatted = ActiveSupport::NumberHelper.number_to_delimited(trm.to_i)
    trm_link = link_to("Editar TRM", admin_site_configs_path, target: "_blank")

    f.inputs "Plan Details" do
      f.input :name
      f.input :price_monthly, label: "Price Monthly (COP)",
              hint: "TRM actual: $#{trm_formatted} COP/USD — #{trm_link}".html_safe
      f.input :price_monthly_usd, label: "Price Monthly (USD)",
              hint: "Se calcula automaticamente al cambiar COP (y viceversa)"
      f.input :max_employees
      f.input :max_services
      f.input :max_reservations_month
      f.input :max_customers
    end
    f.inputs "Feature Flags" do
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

    # Features list (shown to users in plan cards)
    f.inputs "Features del Plan (visibles al cliente)" do
      f.template.concat(
        f.template.content_tag(:div, id: "features-container") do
          items = f.object.features || []
          safe_join(
            items.each_with_index.map { |feat, i|
              content_tag(:div, class: "feature-row", style: "display:flex;gap:8px;margin-bottom:8px;align-items:center;") do
                content_tag(:input, nil, type: "text", name: "plan[features][]", value: feat, style: "flex:1;padding:6px 10px;border:1px solid #ccc;border-radius:4px;") +
                content_tag(:button, "✕", type: "button", class: "remove-feature", style: "background:#ef4444;color:white;border:none;border-radius:4px;padding:4px 10px;cursor:pointer;")
              end
            }
          )
        end
      )
      f.template.concat(
        content_tag(:button, "+ Agregar feature", type: "button", id: "add-feature-btn",
          style: "margin-top:8px;background:#7c3aed;color:white;border:none;border-radius:6px;padding:8px 16px;cursor:pointer;font-size:13px;")
      )
    end

    f.actions
    # JS for TRM auto-calc and features add/remove is in app/assets/javascripts/active_admin.js
  end
end
