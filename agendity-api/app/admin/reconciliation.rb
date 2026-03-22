# frozen_string_literal: true

ActiveAdmin.register_page "Reconciliacion" do
  menu priority: 13, label: "Reconciliacion"

  content do
    if params[:business_id].present?
      business = Business.friendly.find(params[:business_id])

      # Run reconciliations
      cash_result = CashRegister::ReconciliationService.call(business: business)
      credits_result = Credits::ReconciliationService.call(business: business)

      panel "Reconciliacion: #{business.name}" do
        # Cash Register section
        h3 "Cierre de Caja - Saldos de Empleados"
        if cash_result.data.empty?
          status_tag("OK - Todo cuadra", class: "ok")
        else
          table_for cash_result.data do
            column("Empleado") { |d| d[:employee_name] }
            column("Esperado") { |d| number_to_currency(d[:expected], unit: "$", precision: 2) }
            column("Actual") { |d| number_to_currency(d[:actual], unit: "$", precision: 2) }
            column("Diferencia") { |d| number_to_currency(d[:difference], unit: "$", precision: 2) }
            column("Accion") do |d|
              link_to "Auto-corregir",
                admin_reconciliacion_path(business_id: business.slug, fix_cash: d[:employee_id]),
                method: :post,
                data: { confirm: "Corregir saldo de #{d[:employee_name]}?" }
            end
          end
        end

        hr

        # Credits section
        h3 "Creditos - Cuentas de Clientes"
        if credits_result.data.empty?
          status_tag("OK - Todo cuadra", class: "ok")
        else
          table_for credits_result.data do
            column("Cliente") { |d| d[:customer_name] }
            column("Esperado") { |d| number_to_currency(d[:expected], unit: "$", precision: 2) }
            column("Actual") { |d| number_to_currency(d[:actual], unit: "$", precision: 2) }
            column("Diferencia") { |d| number_to_currency(d[:difference], unit: "$", precision: 2) }
            column("Accion") do |d|
              link_to "Auto-corregir",
                admin_reconciliacion_path(business_id: business.slug, fix_credits: d[:credit_account_id]),
                method: :post,
                data: { confirm: "Corregir saldo de #{d[:customer_name]}?" }
            end
          end
        end
      end
    else
      # Business selection
      panel "Seleccionar negocio para reconciliar" do
        table_for Business.active.includes(:owner).order(:name) do
          column(:name) { |b| link_to b.name, admin_reconciliacion_path(business_id: b.slug) }
          column(:owner) { |b| b.owner.name }
          column(:employees) { |b| b.employees.count }
          column(:city) { |b| b.city }
          column("Reconciliar") do |b|
            link_to "Ejecutar", admin_reconciliacion_path(business_id: b.slug), class: "button"
          end
        end
      end
    end
  end

  # POST action to auto-fix individual discrepancies
  page_action :fix, method: :post do
    business = Business.friendly.find(params[:business_id])

    if params[:fix_cash].present?
      employee = business.employees.find(params[:fix_cash])
      # Recalculate expected balance
      payments_balance = employee.employee_payments.sum("total_owed - amount_paid")
      adjustments_balance = employee.employee_balance_adjustments.sum(:amount)
      expected = payments_balance + adjustments_balance
      employee.update!(pending_balance: expected)
      redirect_to admin_reconciliacion_path(business_id: business.slug),
        notice: "Saldo de #{employee.name} corregido a $#{expected.to_i}"
    elsif params[:fix_credits].present?
      account = business.credit_accounts.find(params[:fix_credits])
      expected = [account.credit_transactions.sum(:amount), 0].max
      account.update!(balance: expected)
      redirect_to admin_reconciliacion_path(business_id: business.slug),
        notice: "Saldo de credito corregido a $#{expected.to_i}"
    else
      redirect_to admin_reconciliacion_path(business_id: business.slug),
        alert: "No se especifico que corregir"
    end
  end
end
