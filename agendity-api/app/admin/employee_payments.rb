# frozen_string_literal: true

ActiveAdmin.register EmployeePayment do
  menu parent: "Finanzas", priority: 4, label: "Pagos a Empleados"

  actions :index, :show

  filter :payment_method, as: :select, collection: EmployeePayment.payment_methods.keys
  filter :created_at

  index do
    id_column
    column(:negocio) { |ep| ep.cash_register_close&.business&.name }
    column(:fecha_cierre) { |ep| ep.cash_register_close&.date }
    column(:empleado) { |ep| ep.employee&.name }
    column(:ingresos) { |ep| "$#{ep.total_earned.to_f.round(0).to_fs(:delimited)}" }
    column(:comision) { |ep| "#{ep.commission_pct}% ($#{ep.commission_amount.to_f.round(0).to_fs(:delimited)})" }
    column(:pendiente_anterior) { |ep| ep.pending_from_previous.to_f > 0 ? "$#{ep.pending_from_previous.to_f.round(0)}" : "—" }
    column(:total_adeudado) { |ep| "$#{ep.total_owed.to_f.round(0).to_fs(:delimited)}" }
    column(:pagado) { |ep| "$#{ep.amount_paid.to_f.round(0).to_fs(:delimited)}" }
    column :payment_method
    column(:comprobante) { |ep| ep.proof.attached? ? status_tag("Si", class: "ok") : "—" }
    actions
  end

  show do
    attributes_table do
      row :id
      row(:negocio) { |ep| ep.cash_register_close&.business&.name }
      row(:cierre_de_caja) { |ep| link_to("Cierre ##{ep.cash_register_close_id}", admin_cash_register_close_path(ep.cash_register_close_id)) }
      row(:empleado) { |ep| ep.employee&.name }
      row(:ingresos_generados) { |ep| "$#{ep.total_earned.to_f.round(2)}" }
      row(:comision) { |ep| "#{ep.commission_pct}% = $#{ep.commission_amount.to_f.round(2)}" }
      row(:pendiente_anterior) { |ep| "$#{ep.pending_from_previous.to_f.round(2)}" }
      row(:total_adeudado) { |ep| "$#{ep.total_owed.to_f.round(2)}" }
      row(:monto_pagado) { |ep| "$#{ep.amount_paid.to_f.round(2)}" }
      row(:deuda_restante) { |ep| "$#{[ep.total_owed.to_f - ep.amount_paid.to_f, 0].max.round(2)}" }
      row :payment_method
      row :notes
      row(:comprobante) { |ep|
        if ep.proof.attached?
          image_tag(rails_blob_path(ep.proof, only_path: true), style: "max-width: 400px; border-radius: 8px;")
        else
          "No adjunto"
        end
      }
    end
  end
end
