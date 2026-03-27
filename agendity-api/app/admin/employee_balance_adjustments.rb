# frozen_string_literal: true

ActiveAdmin.register EmployeeBalanceAdjustment do
  menu parent: "Finanzas", priority: 5, label: "Ajustes de Saldo"
  actions :index, :show

  includes :business, :employee, :performed_by_user

  # -- Index --
  index do
    selectable_column
    id_column
    column(:business) { |adj| link_to adj.business.name, admin_business_path(adj.business) }
    column(:employee) { |adj| adj.employee.name }
    column(:amount) { |adj| number_to_currency(adj.amount, unit: "$", precision: 0) }
    column(:balance_before) { |adj| number_to_currency(adj.balance_before, unit: "$", precision: 0) }
    column(:balance_after) { |adj| number_to_currency(adj.balance_after, unit: "$", precision: 0) }
    column :reason
    column(:performed_by) { |adj| adj.performed_by_user.name }
    column :created_at
    actions
  end

  # -- Filters --
  filter :business
  filter :employee
  filter :reason
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |adj| link_to adj.business.name, admin_business_path(adj.business) }
      row(:employee) { |adj| adj.employee.name }
      row(:performed_by) { |adj| adj.performed_by_user.name }
      row(:amount) { |adj| number_to_currency(adj.amount, unit: "$", precision: 2) }
      row(:balance_before) { |adj| number_to_currency(adj.balance_before, unit: "$", precision: 2) }
      row(:balance_after) { |adj| number_to_currency(adj.balance_after, unit: "$", precision: 2) }
      row :reason
      row :notes
      row :created_at
    end
  end
end
