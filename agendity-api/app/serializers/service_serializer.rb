# frozen_string_literal: true

class ServiceSerializer < Blueprinter::Base
  identifier :id

  fields :business_id, :name, :description, :duration_minutes,
         :price, :active, :category, :image_url,
         :created_at, :updated_at
end
