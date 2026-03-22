# frozen_string_literal: true

ActiveAdmin.register CreditAccount do
  menu parent: "Finanzas", priority: 1, label: "Cuentas de Credito"

  actions :index, :show

  filter :business, as: :select, collection: -> { Business.order(:name).pluck(:name, :id) }
  filter :customer
  filter :balance
  filter :created_at

  index do
    id_column
    column :business
    column(:customer) { |ca| ca.customer&.name }
    column(:email) { |ca| ca.customer&.email }
    column(:balance) { |ca| "$#{ca.balance.to_f.round(0).to_fs(:delimited)}" }
    column(:transactions) { |ca| ca.credit_transactions.count }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :business
      row(:customer) { |ca| ca.customer&.name }
      row(:email) { |ca| ca.customer&.email }
      row(:balance) { |ca| "$#{ca.balance.to_f.round(0).to_fs(:delimited)}" }
      row :created_at
    end

    panel "Transacciones" do
      table_for resource.credit_transactions.order(created_at: :desc) do
        column :id
        column(:fecha) { |t| t.created_at.strftime("%Y-%m-%d %H:%M") }
        column :transaction_type
        column(:monto) { |t| "#{t.amount >= 0 ? '+' : ''}$#{t.amount.to_f.round(0).to_fs(:delimited)}" }
        column :description
        column(:appointment) { |t| t.appointment_id ? link_to("##{t.appointment_id}", admin_appointment_path(t.appointment_id)) : "—" }
        column(:realizado_por) { |t| t.performed_by_user&.name || "Sistema" }
      end
    end

    panel "Verificacion" do
      expected = resource.credit_transactions.sum(:amount).to_f
      actual = resource.balance.to_f
      diff = (actual - expected).round(2)

      if diff.zero?
        status_tag "Consistente", class: "ok"
        para "Balance ($#{actual.round(0)}) coincide con la suma de transacciones."
      else
        status_tag "Discrepancia", class: "error"
        para "Balance actual: $#{actual.round(0)}"
        para "Suma transacciones: $#{expected.round(0)}"
        para "Diferencia: $#{diff.round(0)}"
      end
    end
  end
end
