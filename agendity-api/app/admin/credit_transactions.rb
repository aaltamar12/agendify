# frozen_string_literal: true

ActiveAdmin.register CreditTransaction do
  menu parent: "Finanzas", priority: 2, label: "Transacciones de Credito"

  actions :index, :show

  filter :transaction_type, as: :select, collection: CreditTransaction.transaction_types.keys
  filter :created_at

  index do
    id_column
    column(:negocio) { |t| t.credit_account&.business&.name }
    column(:cliente) { |t| t.credit_account&.customer&.name }
    column :transaction_type
    column(:monto) { |t| "#{t.amount >= 0 ? '+' : ''}$#{t.amount.to_f.round(0).to_fs(:delimited)}" }
    column :description
    column(:cita) { |t| t.appointment_id ? link_to("##{t.appointment_id}", admin_appointment_path(t.appointment_id)) : "—" }
    column(:realizado_por) { |t| t.performed_by_user&.name || "Sistema" }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row(:negocio) { |t| t.credit_account&.business&.name }
      row(:cliente) { |t| t.credit_account&.customer&.name }
      row :transaction_type
      row(:monto) { |t| "$#{t.amount.to_f.round(2)}" }
      row :description
      row(:appointment) { |t| t.appointment_id ? link_to("Cita ##{t.appointment_id}", admin_appointment_path(t.appointment_id)) : "N/A" }
      row(:realizado_por) { |t| t.performed_by_user&.name || "Sistema" }
      row :metadata
      row :created_at
    end
  end
end
