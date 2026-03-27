# frozen_string_literal: true

ActiveAdmin.register Business do
  menu parent: "Negocios", priority: 1, label: "Negocios"

  # -- friendly_id support --
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      scoped_collection.find(params[:id])
    end
  end

  permit_params :name, :business_type, :status, :description, :phone, :email,
                :address, :city, :state, :country, :logo_url, :cover_image_url,
                :instagram_url, :facebook_url, :website_url, :google_maps_url,
                :timezone, :currency,
                :nequi_phone, :daviplata_phone, :bancolombia_account,
                :cancellation_policy_pct, :cancellation_deadline_hours,
                :trial_ends_at, :onboarding_completed, :primary_color, :secondary_color,
                :nit, :legal_representative_name, :legal_representative_document,
                :legal_representative_document_type, :independent,
                :birthday_campaign_enabled, :birthday_discount_pct, :birthday_discount_days_valid,
                :virtual_business

  # -- Index --
  includes :owner

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :business_type
    column(:independent) do |b|
      if b.independent?
        status_tag("Independiente", class: "", style: "background: #8b5cf6; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
      else
        status_tag("Establecimiento", class: "", style: "background: #6b7280; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
      end
    end
    column(:virtual_business) do |b|
      if b.virtual_business?
        status_tag("Virtual", class: "", style: "background: #06b6d4; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
      end
    end
    column(:status) do |b|
      color = case b.status
              when "active" then "#22c55e"
              when "suspended" then "#eab308"
              when "inactive" then "#ef4444"
              end
      label = case b.status
              when "active" then "Activo"
              when "suspended" then "Oculto"
              when "inactive" then "Desactivado"
              end
      status_tag(label, class: "", style: "background: #{color}; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
    end
    column(:owner) { |b| link_to b.owner.name, admin_user_path(b.owner) }
    column :city
    column :rating_average
    bool_column :onboarding_completed
    column(:trial) do |b|
      if b.subscriptions.active.where("end_date >= ?", Date.current).exists?
        status_tag("Pagado", class: "", style: "background: #22c55e; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
      elsif b.trial_ends_at.present? && b.trial_ends_at > Time.current
        days = ((b.trial_ends_at - Time.current) / 1.day).ceil
        status_tag("Trial (#{days}d)", class: "", style: "background: #f59e0b; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
      elsif b.trial_ends_at.present?
        status_tag("Expirado", class: "", style: "background: #ef4444; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
      else
        "—"
      end
    end
    column :created_at
    actions
  end

  # -- Filters --
  filter :name
  filter :status, as: :select, collection: -> { Business.statuses.keys }
  filter :business_type, as: :select, collection: -> { Business.business_types.keys }
  filter :independent
  filter :city
  filter :onboarding_completed
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :business_type
      row(:status) do |b|
        color = case b.status
                when "active" then "#22c55e"
                when "suspended" then "#eab308"
                when "inactive" then "#ef4444"
                end
        label = case b.status
                when "active" then "Activo"
                when "suspended" then "Oculto"
                when "inactive" then "Desactivado"
                end
        status_tag(label, class: "", style: "background: #{color}; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
      end
      row(:owner) { |b| link_to b.owner.name, admin_user_path(b.owner) }
      row :description
      row :phone
      row :email
      row :address
      row :city
      row :state
      row :country
      row :website_url
      row :google_maps_url
      row :latitude
      row :longitude
      row :rating_average
      row :total_reviews
      row :timezone
      row :currency
      row :onboarding_completed
      row :trial_ends_at
      row :nequi_phone
      row :daviplata_phone
      row :bancolombia_account
      row :cancellation_policy_pct
      row :cancellation_deadline_hours
      row :primary_color
      row :secondary_color
      row(:independent) do |b|
        if b.independent?
          status_tag("Si - Profesional Independiente", class: "", style: "background: #8b5cf6; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
        else
          "No"
        end
      end
      row(:virtual_business) do |b|
        if b.virtual_business?
          status_tag("Si - Negocio Virtual", class: "", style: "background: #06b6d4; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;")
        else
          "No"
        end
      end
      row :nit
      row :legal_representative_name
      row :legal_representative_document
      row :legal_representative_document_type
      row :created_at
      row :updated_at
    end

    panel "Statistics" do
      ul do
        li "Services: #{business.services.count}"
        li "Employees: #{business.employees.count}"
        li "Appointments: #{business.appointments.count}"
        li "Customers: #{business.customers.count}"
        li "Reviews: #{business.reviews.count}"
      end
    end
  end

  # -- Form --
  form do |f|
    f.inputs "Basic Info" do
      f.input :name
      f.input :business_type, as: :select, collection: Business.business_types.keys
      f.input :status, as: :select, collection: Business.statuses.keys.map { |k|
        label = case k
                when "active" then "Activo (visible)"
                when "suspended" then "Oculto (no aparece en explore, dashboard funcional)"
                when "inactive" then "Desactivado (bloqueado completamente)"
                end
        [label, k]
      }
      f.input :description
      f.input :phone
      f.input :email
      f.input :onboarding_completed
    end
    f.inputs "Location" do
      f.input :country, as: :select,
        collection: CS.countries.map { |code, name| [name, code.to_s] }.sort_by(&:first),
        include_blank: "Seleccionar país...",
        input_html: { id: "loc_country" }
      f.input :state, as: :select,
        collection: [],
        include_blank: "Seleccionar estado...",
        input_html: { id: "loc_state" }
      f.input :city, as: :select,
        collection: [],
        include_blank: "Seleccionar ciudad...",
        input_html: { id: "loc_city" }
      f.input :address
      f.input :timezone
      f.input :website_url
      f.input :google_maps_url
    end

    # JavaScript for cascading location selects (works with Select2)
    f.template.text_node javascript_tag(<<~JS)
      (function() {
        var $ = jQuery;
        var apiBase = '/api/v1/locations';
        var initialState = '#{f.object.state}';
        var initialCity  = '#{f.object.city}';

        function refreshSelect(el, items, placeholder, selectedValue) {
          var $el = $(el);
          // Destroy existing Select2
          try { $el.select2('destroy'); } catch(e) {}
          // Rebuild native options
          el.innerHTML = '<option value="">' + placeholder + '</option>';
          items.forEach(function(item) {
            var opt = document.createElement('option');
            opt.value = item.code || item.name;
            opt.textContent = item.name;
            if (selectedValue && (item.code === selectedValue || item.name === selectedValue)) {
              opt.selected = true;
            }
            el.appendChild(opt);
          });
          // Re-init Select2
          $el.select2({ allowClear: true, placeholder: placeholder });
        }

        function loadStates(country, selectValue) {
          var stateEl = document.getElementById('loc_state');
          var cityEl  = document.getElementById('loc_city');
          if (!country) {
            refreshSelect(stateEl, [], 'Seleccionar estado...', null);
            refreshSelect(cityEl, [], 'Seleccionar ciudad...', null);
            return;
          }
          fetch(apiBase + '/states?country=' + country)
            .then(function(r) { return r.json(); })
            .then(function(json) {
              refreshSelect(stateEl, json.data, 'Seleccionar estado...', selectValue);
              if (stateEl.value) loadCities(country, stateEl.value, initialCity);
            });
        }

        function loadCities(country, state, selectValue) {
          var cityEl = document.getElementById('loc_city');
          if (!country || !state) {
            refreshSelect(cityEl, [], 'Seleccionar ciudad...', null);
            return;
          }
          fetch(apiBase + '/cities?country=' + country + '&state=' + state)
            .then(function(r) { return r.json(); })
            .then(function(json) {
              refreshSelect(cityEl, json.data, 'Seleccionar ciudad...', selectValue);
            });
        }

        function init() {
          var countryEl = document.getElementById('loc_country');
          var stateEl   = document.getElementById('loc_state');

          // Listen for Select2 change events
          $(countryEl).on('change', function() {
            initialState = null; initialCity = null;
            loadStates(this.value, null);
          });

          $(stateEl).on('change', function() {
            initialCity = null;
            loadCities(countryEl.value, this.value, null);
          });

          // Load initial data
          if (countryEl.value) loadStates(countryEl.value, initialState);
        }

        // Run after Select2 has initialized
        $(document).ready(function() { setTimeout(init, 200); });
      })();
    JS
    f.inputs "Branding" do
      f.input :logo_url
      f.input :cover_image_url
      f.input :instagram_url
      f.input :facebook_url
      f.input :primary_color
      f.input :secondary_color
      f.input :currency
    end
    f.inputs "Payment Info (encrypted)" do
      f.input :nequi_phone
      f.input :daviplata_phone
      f.input :bancolombia_account
    end
    f.inputs "Cancellation Policy" do
      f.input :cancellation_policy_pct, label: "Cancellation penalty %"
      f.input :cancellation_deadline_hours
    end
    f.inputs "Legal / Independiente" do
      f.input :independent
      f.input :virtual_business, label: "Negocio Virtual (solicita info adicional en pago)"
      f.input :nit
      f.input :legal_representative_name
      f.input :legal_representative_document
      f.input :legal_representative_document_type, as: :select,
        collection: [["CC", "CC"], ["CE", "CE"], ["NIT", "NIT"], ["Pasaporte", "passport"]],
        include_blank: "Seleccionar..."
    end
    f.inputs "Birthday Campaign" do
      f.input :birthday_campaign_enabled, label: "Enabled"
      f.input :birthday_discount_pct, label: "Discount %"
      f.input :birthday_discount_days_valid, label: "Days valid"
    end
    f.inputs "Trial" do
      f.input :trial_ends_at, as: :datepicker
    end
    f.actions
  end

  # -- Batch Actions --
  batch_action :activate, confirm: "¿Activar los negocios seleccionados?" do |ids|
    batch_action_collection.find(ids).each { |b| b.update!(status: :active) }
    redirect_to collection_path, notice: "#{ids.size} negocio(s) activados."
  end

  batch_action :hide, confirm: "¿Ocultar los negocios seleccionados? (quedan en estado 'suspended')" do |ids|
    batch_action_collection.find(ids).each { |b| b.update!(status: :suspended) }
    redirect_to collection_path, notice: "#{ids.size} negocio(s) ocultados."
  end

  batch_action :deactivate, confirm: "¿Desactivar completamente los negocios seleccionados?" do |ids|
    batch_action_collection.find(ids).each { |b| b.update!(status: :inactive) }
    redirect_to collection_path, notice: "#{ids.size} negocio(s) desactivados."
  end

  # -- Actions --
  member_action :approve, method: :put do
    resource.update!(status: :active)
    redirect_to admin_business_path(resource), notice: "Negocio activado."
  end

  member_action :suspend, method: :put do
    resource.update!(status: :suspended)
    redirect_to admin_business_path(resource), notice: "Negocio ocultado (suspended)."
  end

  member_action :deactivate, method: :put do
    resource.update!(status: :inactive)
    redirect_to admin_business_path(resource), notice: "Negocio desactivado completamente."
  end

  member_action :activate, method: :put do
    resource.update!(status: :active)
    redirect_to admin_business_path(resource), notice: "Negocio activado."
  end

  action_item :approve, only: :show, if: proc { resource.inactive? } do
    link_to "Activar", approve_admin_business_path(resource), method: :put
  end

  action_item :suspend, only: :show, if: proc { resource.active? } do
    link_to "Ocultar", suspend_admin_business_path(resource), method: :put
  end

  action_item :deactivate, only: :show, if: proc { !resource.inactive? } do
    link_to "Desactivar", deactivate_admin_business_path(resource), method: :put,
            data: { confirm: "¿Desactivar completamente este negocio? El dueño perderá acceso al dashboard." }
  end

  action_item :activate, only: :show, if: proc { resource.suspended? } do
    link_to "Activar", activate_admin_business_path(resource), method: :put
  end
end
