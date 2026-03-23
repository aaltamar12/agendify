# frozen_string_literal: true

ActiveAdmin.register SubscriptionPaymentOrder do
  menu priority: 9, label: "Payment Orders"
  actions :index, :show

  # -- Eager loading --
  includes :business, :plan, subscription: :plan

  # -- Index --
  index do
    selectable_column
    id_column
    column(:business) { |o| link_to o.business.name, admin_business_path(o.business) }
    column(:plan) { |o| (o.plan || o.subscription&.plan)&.name || "—" }
    column(:amount) { |o| number_to_currency(o.amount, unit: "$", precision: 0) }
    column :due_date
    column :status do |o|
      status_tag o.status, class: case o.status
                                   when "paid" then "ok"
                                   when "pending" then "warning"
                                   when "overdue" then "error"
                                   when "proof_submitted" then "warning"
                                   when "rejected" then "error"
                                   else "default"
                                   end
    end
    column(:period) { |o| "#{o.period_start.strftime('%d/%m/%Y')} — #{o.period_end.strftime('%d/%m/%Y')}" }
    column :proof_submitted_at
    column :created_at
    actions
  end

  # -- Filters --
  filter :status, as: :select, collection: %w[pending paid overdue cancelled proof_submitted rejected]
  filter :due_date
  filter :business

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:business) { |o| link_to o.business.name, admin_business_path(o.business) }
      row(:plan) { |o| (o.plan || o.subscription&.plan)&.name || "—" }
      row(:amount) { |o| number_to_currency(o.amount, unit: "$", precision: 0) }
      row :due_date
      row :period_start
      row :period_end
      row :status
      row :proof_submitted_at
      row :reviewed_by
      row :reviewed_at
      row :notes
      row :created_at
      row :updated_at
      row(:proof) do |o|
        if o.proof.attached?
          if o.proof.content_type&.start_with?("image/")
            image_tag rails_blob_path(o.proof, disposition: "inline"), style: "max-width: 400px; max-height: 400px;"
          else
            link_to "Download proof", rails_blob_path(o.proof, disposition: "attachment")
          end
        else
          "No proof uploaded"
        end
      end
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

  # -- Approve proof action --
  action_item :approve_proof, only: :show do
    if resource.status == "proof_submitted"
      link_to "Aprobar comprobante", approve_proof_admin_subscription_payment_order_path(resource), method: :put,
        data: { confirm: "Esto creara/extenderaa la suscripcion y activara el negocio. Continuar?" }
    end
  end

  member_action :approve_proof, method: :put do
    result = Subscriptions::ApprovePaymentService.call(
      order: resource,
      reviewed_by: current_admin_user.email
    )

    if result.success?
      redirect_to admin_subscription_payment_order_path(resource), notice: "Comprobante aprobado. Suscripcion activada."
    else
      redirect_to admin_subscription_payment_order_path(resource), alert: "Error: #{result.error}"
    end
  end

  # -- Reject proof action --
  action_item :reject_proof, only: :show do
    if resource.status == "proof_submitted"
      link_to "Rechazar comprobante", reject_proof_admin_subscription_payment_order_path(resource), method: :put,
        data: { confirm: "Rechazar este comprobante?" }
    end
  end

  member_action :reject_proof, method: :put do
    resource.update!(
      status: "rejected",
      reviewed_by: current_admin_user.email,
      reviewed_at: Time.current
    )
    redirect_to admin_subscription_payment_order_path(resource), notice: "Comprobante rechazado."
  end
end
