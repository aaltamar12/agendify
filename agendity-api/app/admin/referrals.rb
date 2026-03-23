# frozen_string_literal: true

ActiveAdmin.register Referral do
  menu priority: 12, label: "Referrals"
  actions :index, :show

  # -- Eager loading --
  includes :referral_code, :subscription, business: :owner

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
    column :activated_at
    column :paid_at
    column :created_at
    actions
  end

  # -- Filters --
  filter :status, as: :select, collection: Referral.statuses.keys
  filter :referral_code, as: :select, collection: -> { ReferralCode.pluck(:code, :id) }
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
  end

  # -- Mark as paid action --
  action_item :mark_as_paid, only: :show do
    if resource.activated?
      link_to "Mark as Paid", mark_as_paid_admin_referral_path(resource), method: :put
    end
  end

  member_action :mark_as_paid, method: :put do
    resource.mark_paid!
    redirect_to admin_referral_path(resource), notice: "Referral marked as paid."
  end
end
