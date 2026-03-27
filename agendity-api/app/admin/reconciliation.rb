# frozen_string_literal: true

ActiveAdmin.register_page "Reconciliacion" do
  menu parent: "Finanzas", priority: 6, label: "Reconciliación"

  content do
    if params[:business_id].present?
      business = Business.friendly.find(params[:business_id])

      cash_result = CashRegister::ReconciliationService.call(business: business)
      credits_result = Credits::ReconciliationService.call(business: business)

      panel "Reconciliacion: #{business.name}" do
        h3 "Cierre de Caja — Saldos de Empleados"

        if cash_result.data.empty?
          div class: "flash flash_notice" do
            "OK — Todos los saldos de empleados son consistentes."
          end
        else
          cash_result.data.each do |d|
            div style: "border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; margin-bottom: 16px; background: #fefce8;" do
              h4 "#{d[:employee_name]} — Discrepancia de $#{d[:difference].abs.round(0)}", style: "margin: 0 0 12px 0; color: #92400e;"

              # Detail breakdown
              div style: "display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; margin-bottom: 12px;" do
                div style: "background: white; padding: 8px 12px; border-radius: 6px;" do
                  para "Esperado", style: "font-size: 11px; color: #6b7280; margin: 0;"
                  para "$#{d[:expected].round(0)}", style: "font-size: 18px; font-weight: 700; margin: 0;"
                end
                div style: "background: white; padding: 8px 12px; border-radius: 6px;" do
                  para "Actual (en BD)", style: "font-size: 11px; color: #6b7280; margin: 0;"
                  para "$#{d[:actual].round(0)}", style: "font-size: 18px; font-weight: 700; color: #dc2626; margin: 0;"
                end
                div style: "background: white; padding: 8px 12px; border-radius: 6px;" do
                  para "Diferencia", style: "font-size: 11px; color: #6b7280; margin: 0;"
                  para "$#{d[:difference].round(0)}", style: "font-size: 18px; font-weight: 700; color: #ea580c; margin: 0;"
                end
              end

              # Payments history that generate expected value
              employee = business.employees.find(d[:employee_id])
              payments = employee.employee_payments.includes(cash_register_close: :business).order("cash_register_closes.date DESC")
              adjustments = employee.employee_balance_adjustments.order(created_at: :desc)

              if payments.any?
                para "Historial de pagos (cierres de caja):", style: "font-weight: 600; font-size: 13px; margin-bottom: 4px;"
                table_for payments do
                  column("Fecha") { |p| p.cash_register_close&.date }
                  column("Adeudado") { |p| "$#{p.total_owed.to_f.round(0)}" }
                  column("Pagado") { |p| "$#{p.amount_paid.to_f.round(0)}" }
                  column("Pendiente") { |p| "$#{(p.total_owed.to_f - p.amount_paid.to_f).round(0)}" }
                  column("Metodo") { |p| p.payment_method }
                end
              end

              if adjustments.any?
                para "Ajustes manuales:", style: "font-weight: 600; font-size: 13px; margin: 8px 0 4px 0;"
                table_for adjustments do
                  column("Fecha") { |a| a.created_at.strftime("%Y-%m-%d") }
                  column("Monto") { |a| "$#{a.amount.to_f.round(0)}" }
                  column("Razon") { |a| a.reason }
                  column("Por") { |a| a.performed_by_user&.name || "—" }
                end
              end

              para style: "font-size: 12px; color: #6b7280; margin-top: 8px;" do
                text_node "Calculo: sum(adeudado - pagado) + sum(ajustes) = $#{d[:expected].round(0)}"
              end

              div style: "margin-top: 12px;" do
                text_node link_to("Auto-corregir a $#{d[:expected].round(0)}",
                  admin_reconciliacion_path(business_id: business.slug, fix_cash: d[:employee_id]),
                  method: :post,
                  data: { confirm: "Corregir pending_balance de #{d[:employee_name]} de $#{d[:actual].round(0)} a $#{d[:expected].round(0)}?" },
                  class: "button")
              end
            end
          end
        end

        hr

        h3 "Creditos — Cuentas de Clientes"

        if credits_result.data.empty?
          div class: "flash flash_notice" do
            "OK — Todos los saldos de creditos son consistentes."
          end
        else
          credits_result.data.each do |d|
            div style: "border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; margin-bottom: 16px; background: #fef2f2;" do
              h4 "#{d[:customer_name]} — Discrepancia de $#{d[:difference].abs.round(0)}", style: "margin: 0 0 12px 0; color: #991b1b;"

              div style: "display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; margin-bottom: 12px;" do
                div style: "background: white; padding: 8px 12px; border-radius: 6px;" do
                  para "Esperado (sum txns)", style: "font-size: 11px; color: #6b7280; margin: 0;"
                  para "$#{d[:expected].round(0)}", style: "font-size: 18px; font-weight: 700; margin: 0;"
                end
                div style: "background: white; padding: 8px 12px; border-radius: 6px;" do
                  para "Actual (balance)", style: "font-size: 11px; color: #6b7280; margin: 0;"
                  para "$#{d[:actual].round(0)}", style: "font-size: 18px; font-weight: 700; color: #dc2626; margin: 0;"
                end
                div style: "background: white; padding: 8px 12px; border-radius: 6px;" do
                  para "Diferencia", style: "font-size: 11px; color: #6b7280; margin: 0;"
                  para "$#{d[:difference].round(0)}", style: "font-size: 18px; font-weight: 700; color: #ea580c; margin: 0;"
                end
              end

              # Transaction history
              account = business.credit_accounts.find(d[:credit_account_id])
              transactions = account.credit_transactions.order(created_at: :desc)

              if transactions.any?
                para "Transacciones:", style: "font-weight: 600; font-size: 13px; margin-bottom: 4px;"
                table_for transactions do
                  column("Fecha") { |t| t.created_at.strftime("%Y-%m-%d %H:%M") }
                  column("Tipo") { |t| t.transaction_type }
                  column("Monto") { |t| "#{t.amount >= 0 ? '+' : ''}$#{t.amount.to_f.round(0)}" }
                  column("Descripcion") { |t| t.description }
                  column("Cita") { |t| t.appointment_id ? "##{t.appointment_id}" : "—" }
                end
              end

              para style: "font-size: 12px; color: #6b7280; margin-top: 8px;" do
                text_node "Calculo: sum(transacciones) = $#{d[:expected].round(0)}, pero balance dice $#{d[:actual].round(0)}"
              end

              div style: "margin-top: 12px;" do
                text_node link_to("Auto-corregir balance a $#{d[:expected].round(0)}",
                  admin_reconciliacion_path(business_id: business.slug, fix_credits: d[:credit_account_id]),
                  method: :post,
                  data: { confirm: "Corregir balance de #{d[:customer_name]} de $#{d[:actual].round(0)} a $#{d[:expected].round(0)}?" },
                  class: "button")
              end
            end
          end
        end
      end
    else
      panel "Seleccionar negocio para reconciliar" do
        table_for Business.active.includes(:owner).order(:name) do
          column(:name) { |b| link_to b.name, admin_reconciliacion_path(business_id: b.slug) }
          column(:owner) { |b| b.owner.name }
          column(:employees) { |b| b.employees.count }
          column(:city) { |b| b.city }
          column("Reconciliar") { |b| link_to "Ejecutar", admin_reconciliacion_path(business_id: b.slug), class: "button" }
        end
      end
    end
  end

  page_action :fix, method: :post do
    business = Business.friendly.find(params[:business_id])

    if params[:fix_cash].present?
      employee = business.employees.find(params[:fix_cash])
      payments_balance = employee.employee_payments.sum("total_owed - amount_paid")
      adjustments_balance = employee.employee_balance_adjustments.sum(:amount)
      expected = [payments_balance + adjustments_balance, 0].max
      old_balance = employee.pending_balance
      employee.update!(pending_balance: expected)

      ActivityLog.log(
        business: business,
        action: "reconciliation_fix",
        description: "Saldo de #{employee.name} corregido: $#{old_balance.to_i} → $#{expected.to_i}",
        actor_type: "admin",
        resource: employee,
        metadata: { old_balance: old_balance.to_f, new_balance: expected.to_f }
      )

      redirect_to admin_reconciliacion_path(business_id: business.slug),
        notice: "Saldo de #{employee.name} corregido de $#{old_balance.to_i} a $#{expected.to_i}"
    elsif params[:fix_credits].present?
      account = business.credit_accounts.find(params[:fix_credits])
      expected = [account.credit_transactions.sum(:amount), 0].max
      old_balance = account.balance
      account.update!(balance: expected)

      ActivityLog.log(
        business: business,
        action: "reconciliation_fix",
        description: "Credito de #{account.customer&.name} corregido: $#{old_balance.to_i} → $#{expected.to_i}",
        actor_type: "admin",
        resource: account,
        metadata: { old_balance: old_balance.to_f, new_balance: expected.to_f }
      )

      redirect_to admin_reconciliacion_path(business_id: business.slug),
        notice: "Credito de #{account.customer&.name} corregido de $#{old_balance.to_i} a $#{expected.to_i}"
    else
      redirect_to admin_reconciliacion_path(business_id: business.slug), alert: "No se especifico que corregir"
    end
  end
end
