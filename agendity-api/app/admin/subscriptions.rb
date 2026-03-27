# frozen_string_literal: true

ActiveAdmin.register Subscription do
  menu parent: "Planes y Suscripciones", priority: 2, label: "Suscripciones"

  permit_params :plan_id, :status, :start_date, :end_date

  actions :index, :show, :edit, :update

  # -- Eager loading --
  includes :business, :plan

  # -- Custom Actions --
  action_item :renew, only: :show do
    link_to "Renovar suscripción", renew_admin_subscription_path(resource), method: :put,
      data: { confirm: "¿Renovar esta suscripción por 1 mes más?" }
  end

  member_action :renew, method: :put do
    resource.process_renewal!
    redirect_to admin_subscription_path(resource), notice: "Suscripción renovada hasta #{resource.end_date.strftime('%d/%m/%Y')}."
  end

  # -- Index --
  index do
    selectable_column
    id_column
    column(:business) { |s| link_to s.business.name, admin_business_path(s.business) }
    column(:plan) { |s| link_to s.plan.name, admin_plan_path(s.plan) }
    column :status
    column :start_date
    column :end_date
    column :created_at
    actions
  end

  # -- Filters --
  filter :status, as: :select, collection: -> { Subscription.statuses.keys }
  filter :plan
  filter :start_date
  filter :end_date

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |s| link_to s.business.name, admin_business_path(s.business) }
      row(:plan) { |s| link_to s.plan.name, admin_plan_path(s.plan) }
      row :status
      row :start_date
      row :end_date
      row :created_at
      row :updated_at
    end
  end
end
