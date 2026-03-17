# frozen_string_literal: true

class UserSerializer < Blueprinter::Base
  identifier :id

  fields :email, :name, :phone, :role, :avatar_url,
         :business_id, :created_at, :updated_at

  view :minimal do
    excludes :phone, :role, :avatar_url, :business_id,
             :created_at, :updated_at
  end
end
