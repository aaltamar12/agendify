# frozen_string_literal: true

ActiveAdmin.register AdBanner do
  permit_params :name, :placement, :image_url, :link_url, :alt_text,
                :active, :priority, :start_date, :end_date, :image

  # -- Index --
  index do
    selectable_column
    id_column
    column :name
    column(:placement) { |b| status_tag(b.placement, class: "", style: "background: #7c3aed; color: white; border-radius: 9999px; padding: 2px 10px; font-size: 11px;") }
    bool_column :active
    column :priority
    column :impressions_count
    column :clicks_count
    column("CTR%") { |b| "#{b.ctr}%" }
    column :start_date
    column :end_date
    column :created_at
    actions
  end

  # -- Filters --
  filter :name
  filter :placement, as: :select, collection: -> {
    AdBanner.distinct.pluck(:placement).map { |p| [p, p] }
  }
  filter :active
  filter :start_date
  filter :end_date

  # -- Show --
  show do
    attributes_table do
      row :id
      row :name
      row :placement
      row :image_url
      row :link_url
      row :alt_text
      bool_row :active
      row :priority
      row :start_date
      row :end_date
      row :impressions_count
      row :clicks_count
      row("CTR%") { |b| "#{b.ctr}%" }
      row(:image) do |b|
        if b.image.attached?
          image_tag url_for(b.image), style: "max-width: 400px; max-height: 200px;"
        elsif b.image_url.present?
          image_tag b.image_url, style: "max-width: 400px; max-height: 200px;"
        else
          "No image"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  # -- Form --
  form do |f|
    f.inputs "Ad Banner" do
      f.input :name
      f.input :placement, as: :select, collection: %w[booking_summary booking_confirmation]
      f.input :image, as: :file, hint: f.object.image.attached? ? "Current: #{f.object.image.filename}" : "No image uploaded"
      f.input :image_url, hint: "Fallback URL if no image uploaded"
      f.input :link_url
      f.input :alt_text
      f.input :active
      f.input :priority, hint: "Higher priority = shown first"
      f.input :start_date, as: :datepicker
      f.input :end_date, as: :datepicker
    end
    f.actions
  end
end
