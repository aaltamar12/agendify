# frozen_string_literal: true

ActiveAdmin.register SubscriptionPaymentOrder do
  menu priority: 9, label: "Payment Orders"
  actions :index, :show

  # -- Eager loading --
  includes :business, subscription: :plan

  # -- Index --
  index do
    selectable_column
    id_column
    column(:business) { |o| link_to o.business.name, admin_business_path(o.business) }
    column(:plan) { |o| o.subscription.plan.name }
    column(:amount) { |o| number_to_currency(o.amount, unit: "$", precision: 0) }
    column :due_date
    column :status do |o|
      status_tag o.status, class: case o.status
                                   when "paid" then "ok"
                                   when "pending" then "warning"
                                   when "overdue" then "error"
                                   else "default"
                                   end
    end
    column(:period) { |o| "#{o.period_start.strftime('%d/%m/%Y')} — #{o.period_end.strftime('%d/%m/%Y')}" }
    column :created_at
    actions
  end

  # -- Filters --
  filter :status, as: :select, collection: %w[pending paid overdue cancelled]
  filter :due_date
  filter :business

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |o| link_to o.business.name, admin_business_path(o.business) }
      row(:plan) { |o| o.subscription.plan.name }
      row(:amount) { |o| number_to_currency(o.amount, unit: "$", precision: 0) }
      row :due_date
      row :period_start
      row :period_end
      row :status
      row :notes
      row :created_at
      row :updated_at
    end
  end

  # -- Custom action: mark as paid --
  action_item :mark_as_paid, only: :show do
    if resource.status == "pending" || resource.status == "overdue"
      link_to "Marcar como pagado", mark_as_paid_admin_subscription_payment_order_path(resource), method: :put
    end
  end

  member_action :mark_as_paid, method: :put do
    resource.update!(status: "paid")
    redirect_to admin_subscription_payment_order_path(resource), notice: "Orden marcada como pagada."
  end
end
