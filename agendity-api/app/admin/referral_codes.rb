# frozen_string_literal: true

ActiveAdmin.register ReferralCode do
  menu priority: 11, label: "Referral Codes"
  permit_params :code, :referrer_name, :referrer_email, :referrer_phone,
                :commission_percentage, :status, :notes

  # -- Index --
  index do
    selectable_column
    id_column
    column :code
    column :referrer_name
    column :referrer_email
    column :referrer_phone
    column("Commission %") { |rc| "#{rc.commission_percentage}%" }
    column :status do |rc|
      status_tag rc.status, class: rc.active? ? "ok" : "error"
    end
    column("Total Referrals") { |rc| rc.referrals.count }
    column("Activated") { |rc| rc.referrals.activated.count + rc.referrals.paid.count }
    column("Pending Commission") do |rc|
      amount = rc.referrals.activated.sum(:commission_amount)
      number_to_currency(amount, unit: "$", precision: 0)
    end
    column :created_at
    actions
  end

  # -- Filters --
  filter :code
  filter :referrer_name
  filter :referrer_email
  filter :status, as: :select, collection: ReferralCode.statuses.keys

  # -- Show --
  show do
    attributes_table do
      row :id
      row :code
      row :referrer_name
      row :referrer_email
      row :referrer_phone
      row("Commission %") { |rc| "#{rc.commission_percentage}%" }
      row :status do |rc|
        status_tag rc.status, class: rc.active? ? "ok" : "error"
      end
      row :notes
      row :created_at
      row :updated_at
      row("Referral Link") do |rc|
        app_url = SiteConfig.get("app_url") || "https://app.agendity.com"
        link = "#{app_url}/register?ref=#{rc.code}"
        span link
      end
    end

    panel "Referrals (#{resource.referrals.count})" do
      table_for resource.referrals.includes(business: :owner, subscription: :plan).order(created_at: :desc) do
        column(:business) { |r| link_to r.business.name, admin_business_path(r.business) }
        column :status do |r|
          status_tag r.status, class: case r.status
                                       when "activated" then "ok"
                                       when "pending" then "warning"
                                       when "paid" then "ok"
                                       end
        end
        column(:plan) { |r| r.subscription&.plan&.name || "—" }
        column("Commission") { |r| r.commission_amount ? number_to_currency(r.commission_amount, unit: "$", precision: 0) : "—" }
        column :activated_at
        column :paid_at
      end
    end
  end

  # -- Form --
  form do |f|
    f.inputs "Referral Code" do
      f.input :code, hint: "Leave blank to auto-generate"
      f.input :referrer_name
      f.input :referrer_email
      f.input :referrer_phone
      f.input :commission_percentage, label: "Comision (%)", as: :number, min: 0, max: 100, step: 0.01
      f.input :status, as: :select, collection: ReferralCode.statuses.keys
      f.input :notes
    end
    f.actions
  end
end
