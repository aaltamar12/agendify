# frozen_string_literal: true

ActiveAdmin.register Referral do
  menu parent: "Referidos", priority: 2, label: "Referidos"
  actions :index, :show

  # -- Eager loading --
  includes :referral_code, :subscription, business: :owner

  # -- Batch action: mark selected as paid --
  batch_action "Marcar como pagados", confirm: "¿Marcar los referidos seleccionados como pagados?" do |ids|
    batch_action_collection.find(ids).each do |referral|
      referral.mark_paid! if referral.activated?
    end
    redirect_to collection_path, notice: "Referidos seleccionados marcados como pagados."
  end

  # -- Scopes --
  scope :all, default: true
  scope("Solicitados") { |scope| scope.where.not(disbursement_requested_at: nil).where(status: :activated) }

  # -- Index --
  index do
    selectable_column
    id_column
    column(:referral_code) { |r| link_to r.referral_code.code, admin_referral_code_path(r.referral_code) }
    column(:referrer) { |r| r.referral_code.referrer_name }
    column(:business) { |r| link_to r.business.name, admin_business_path(r.business) }
    column :status do |r|
      status_tag r.status, class: case r.status
                                   when "activated" then "ok"
                                   when "pending" then "warning"
                                   when "paid" then "ok"
                                   end
    end
    column("Commission") { |r| r.commission_amount ? number_to_currency(r.commission_amount, unit: "$", precision: 0) : "—" }
    column("Solicitado") { |r| r.disbursement_requested_at&.strftime("%Y-%m-%d") || "—" }
    column :activated_at
    column :paid_at
    column :created_at
    actions
  end

  # -- Filters --
  filter :status, as: :select, collection: Referral.statuses.keys
  filter :referral_code, as: :select, collection: -> { ReferralCode.pluck(:code, :id) }
  filter :disbursement_requested_at
  filter :created_at

  # -- Show --
  show do
    attributes_table do
      row :id
      row(:referral_code) { |r| link_to r.referral_code.code, admin_referral_code_path(r.referral_code) }
      row(:referrer) { |r| r.referral_code.referrer_name }
      row(:business) { |r| link_to r.business.name, admin_business_path(r.business) }
      row :status
      row("Commission") { |r| r.commission_amount ? number_to_currency(r.commission_amount, unit: "$", precision: 0) : "—" }
      row :activated_at
      row :paid_at
      row :notes
      row :created_at
    end

    panel "Desembolso" do
      attributes_table_for resource do
        row("Solicitado") { |r| r.disbursement_requested_at&.strftime("%Y-%m-%d %H:%M") || "—" }
        row("Pagado") { |r| r.disbursement_paid_at&.strftime("%Y-%m-%d %H:%M") || "—" }
        row("Notas desembolso") { |r| r.disbursement_notes || "—" }
        row("Comprobante") do |r|
          if r.disbursement_proof_file.attached?
            link_to "Ver comprobante", rails_blob_path(r.disbursement_proof_file, only_path: true), target: "_blank", rel: "noopener"
          else
            "—"
          end
        end
      end
    end

    panel "Datos de Pago del Referidor" do
      rc = resource.referral_code
      attributes_table_for rc do
        row(:referrer_name)
        row(:referrer_email)
        row :bank_name
        row :bank_account
        row("Llave Bre-B") { |r| r.breb_key || "—" }
      end
    end
  end

  # -- Mark as paid with proof (form) --
  action_item :mark_as_paid, only: :show do
    if resource.activated?
      link_to "Marcar como pagado", mark_as_paid_form_admin_referral_path(resource)
    end
  end

  member_action :mark_as_paid_form, method: :get do
    @referral = resource
    render inline: <<-ERB, layout: "active_admin"
      <h2>Marcar referido #<%= @referral.id %> como pagado</h2>
      <p><strong>Negocio:</strong> <%= @referral.business.name %></p>
      <p><strong>Comisión:</strong> <%= number_to_currency(@referral.commission_amount, unit: "$", precision: 0) %></p>
      <%= form_tag mark_as_paid_admin_referral_path(@referral), method: :put, multipart: true do %>
        <fieldset class="inputs">
          <ol>
            <li class="string input optional">
              <label>Notas de desembolso</label>
              <%= text_area_tag :disbursement_notes, nil, rows: 3, style: "width:100%" %>
            </li>
            <li class="file input optional">
              <label>Comprobante de pago</label>
              <%= file_field_tag :disbursement_proof %>
            </li>
          </ol>
        </fieldset>
        <%= submit_tag "Confirmar pago", class: "btn" %>
      <% end %>
    ERB
  end

  member_action :mark_as_paid, method: :put do
    resource.mark_paid!(
      notes: params[:disbursement_notes],
      proof_file: params[:disbursement_proof]
    )
    redirect_to admin_referral_path(resource), notice: "Referido marcado como pagado."
  end
end
