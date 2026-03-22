# frozen_string_literal: true

ActiveAdmin.register CashRegisterClose do
  menu parent: "Finanzas", priority: 3, label: "Cierres de Caja"

  actions :index, :show

  filter :business, as: :select, collection: -> { Business.order(:name).pluck(:name, :id) }
  filter :date
  filter :status, as: :select, collection: CashRegisterClose.statuses.keys
  filter :created_at

  index do
    id_column
    column :business
    column :date
    column :status
    column(:ingresos) { |c| "$#{c.total_revenue.to_f.round(0).to_fs(:delimited)}" }
    column :total_appointments
    column(:cerrado_por) { |c| c.closed_by_user&.name }
    column :closed_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :business
      row :date
      row :status
      row(:ingresos) { |c| "$#{c.total_revenue.to_f.round(0).to_fs(:delimited)}" }
      row :total_appointments
      row(:cerrado_por) { |c| c.closed_by_user&.name }
      row :closed_at
      row :notes
    end

    panel "Pagos a Empleados" do
      table_for resource.employee_payments.includes(:employee).order(:id) do
        column(:empleado) { |ep| ep.employee&.name }
        column(:citas) { |ep| ep.appointments_count }
        column(:ingresos) { |ep| "$#{ep.total_earned.to_f.round(0).to_fs(:delimited)}" }
        column(:comision) { |ep| "#{ep.commission_pct}% = $#{ep.commission_amount.to_f.round(0).to_fs(:delimited)}" }
        column(:pendiente_anterior) { |ep| ep.pending_from_previous.to_f > 0 ? "$#{ep.pending_from_previous.to_f.round(0).to_fs(:delimited)}" : "—" }
        column(:total_adeudado) { |ep| "$#{ep.total_owed.to_f.round(0).to_fs(:delimited)}" }
        column(:pagado) { |ep| "$#{ep.amount_paid.to_f.round(0).to_fs(:delimited)}" }
        column(:deuda_restante) { |ep|
          remaining = ep.total_owed.to_f - ep.amount_paid.to_f
          remaining > 0 ? status_tag("$#{remaining.round(0)}", class: "error") : status_tag("$0", class: "ok")
        }
        column :payment_method
        column(:comprobante) { |ep| ep.proof.attached? ? link_to("Ver", rails_blob_path(ep.proof, only_path: true), target: "_blank") : "—" }
      end
    end

    panel "Resumen" do
      total_paid = resource.employee_payments.sum(:amount_paid).to_f
      net = resource.total_revenue.to_f - total_paid
      para "Ingresos: $#{resource.total_revenue.to_f.round(0).to_fs(:delimited)}"
      para "Total pagado a empleados: $#{total_paid.round(0).to_fs(:delimited)}"
      para "Ganancia neta del dia: $#{net.round(0).to_fs(:delimited)}", style: "font-weight: bold; font-size: 16px; color: #{net >= 0 ? 'green' : 'red'}"
    end
  end
end
