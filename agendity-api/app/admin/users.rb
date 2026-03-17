# frozen_string_literal: true

ActiveAdmin.register User do
  permit_params :name, :email, :role, :phone, :password, :password_confirmation

  # -- Index --
  index do
    selectable_column
    id_column
    column :name
    column :email
    column :role
    column :phone
    column :created_at
    actions
  end

  # -- Filters --
  filter :name
  filter :email
  filter :role, as: :select, collection: User.roles.keys
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row :name
      row :email
      row :role
      row :phone
      row :avatar_url
      row :created_at
      row :updated_at
    end

    panel "Businesses" do
      table_for user.businesses do
        column(:name) { |b| link_to b.name, admin_business_path(b) }
        column :business_type
        column :status
        column :city
      end
    end
  end

  # -- Form --
  form do |f|
    f.inputs "User Details" do
      f.input :name
      f.input :email
      f.input :role, as: :select, collection: User.roles.keys
      f.input :phone
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  # Allow update without password
  controller do
    def update
      if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      super
    end
  end
end
