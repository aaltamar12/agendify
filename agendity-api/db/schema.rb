# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_23_221759) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "action", null: false
    t.string "actor_type"
    t.string "actor_name"
    t.text "description"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "created_at"], name: "index_activity_logs_on_business_id_and_created_at"
    t.index ["business_id"], name: "index_activity_logs_on_business_id"
    t.index ["resource_type", "resource_id"], name: "index_activity_logs_on_resource_type_and_resource_id"
  end

  create_table "ad_banners", force: :cascade do |t|
    t.string "name", null: false
    t.string "placement", null: false
    t.string "image_url"
    t.string "link_url"
    t.string "alt_text"
    t.boolean "active", default: true
    t.integer "priority", default: 0
    t.date "start_date"
    t.date "end_date"
    t.integer "impressions_count", default: 0
    t.integer "clicks_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["placement", "active"], name: "index_ad_banners_on_placement_and_active"
  end

  create_table "appointment_services", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.bigint "service_id", null: false
    t.decimal "price", precision: 12, scale: 2
    t.integer "duration_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id", "service_id"], name: "index_appointment_services_on_appointment_id_and_service_id", unique: true
    t.index ["appointment_id"], name: "index_appointment_services_on_appointment_id"
    t.index ["service_id"], name: "index_appointment_services_on_service_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "employee_id", null: false
    t.bigint "service_id", null: false
    t.bigint "customer_id", null: false
    t.date "appointment_date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.string "ticket_code"
    t.string "ticket_url"
    t.text "notes"
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cancellation_reason"
    t.string "cancelled_by"
    t.string "checked_in_by_type"
    t.integer "checked_in_by_id"
    t.boolean "checkin_substitute", default: false
    t.string "checkin_substitute_reason"
    t.decimal "credits_applied", precision: 12, scale: 2, default: "0.0"
    t.bigint "dynamic_pricing_id"
    t.decimal "original_price", precision: 12, scale: 2
    t.bigint "discount_code_id"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.index ["business_id", "appointment_date", "status"], name: "idx_appointments_biz_date_status"
    t.index ["business_id"], name: "index_appointments_on_business_id"
    t.index ["customer_id"], name: "index_appointments_on_customer_id"
    t.index ["discount_code_id"], name: "index_appointments_on_discount_code_id"
    t.index ["employee_id", "appointment_date", "start_time"], name: "idx_appointments_unique_slot", unique: true, where: "(status <> 4)"
    t.index ["employee_id", "appointment_date"], name: "idx_appointments_employee_date"
    t.index ["employee_id"], name: "index_appointments_on_employee_id"
    t.index ["service_id"], name: "index_appointments_on_service_id"
    t.index ["ticket_code"], name: "index_appointments_on_ticket_code", unique: true
  end

  create_table "blocked_slots", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "employee_id"
    t.date "date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "all_day", default: false, null: false
    t.index ["business_id", "date"], name: "idx_blocked_slots_biz_date"
    t.index ["business_id"], name: "index_blocked_slots_on_business_id"
    t.index ["employee_id"], name: "index_blocked_slots_on_employee_id"
  end

  create_table "business_goals", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "goal_type", null: false
    t.string "name"
    t.decimal "target_value", precision: 12, scale: 2, null: false
    t.string "period", default: "monthly"
    t.decimal "fixed_costs", precision: 12, scale: 2
    t.jsonb "metadata", default: {}
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "goal_type"], name: "index_business_goals_on_business_id_and_goal_type"
    t.index ["business_id"], name: "index_business_goals_on_business_id"
  end

  create_table "business_hours", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.integer "day_of_week", null: false
    t.time "open_time", null: false
    t.time "close_time", null: false
    t.boolean "closed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "day_of_week"], name: "index_business_hours_on_business_id_and_day_of_week", unique: true
    t.index ["business_id"], name: "index_business_hours_on_business_id"
  end

  create_table "businesses", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "business_type", default: 0, null: false
    t.text "description"
    t.string "phone"
    t.string "email"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country", default: "CO", null: false
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.string "logo_url"
    t.string "cover_image_url"
    t.string "instagram_url"
    t.string "facebook_url"
    t.decimal "rating_average", precision: 3, scale: 2, default: "0.0", null: false
    t.integer "total_reviews", default: 0, null: false
    t.string "timezone", default: "America/Bogota", null: false
    t.string "currency", default: "COP", null: false
    t.string "nequi_phone"
    t.string "daviplata_phone"
    t.string "bancolombia_account"
    t.integer "cancellation_policy_pct", default: 0, null: false
    t.integer "cancellation_deadline_hours", default: 24, null: false
    t.datetime "trial_ends_at"
    t.integer "status", default: 0, null: false
    t.boolean "onboarding_completed", default: false, null: false
    t.string "primary_color"
    t.string "secondary_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.string "google_maps_url"
    t.string "lunch_start_time", default: "12:00"
    t.string "lunch_end_time", default: "13:00"
    t.boolean "lunch_enabled", default: true
    t.integer "slot_interval_minutes", default: 30
    t.integer "gap_between_appointments_minutes", default: 0
    t.string "cover_source", default: "upload"
    t.jsonb "customer_notification_channels", default: {"push" => false, "email" => true, "whatsapp" => false}
    t.boolean "cashback_enabled", default: false
    t.decimal "cashback_percentage", precision: 5, scale: 2, default: "0.0"
    t.boolean "cancellation_refund_as_credit", default: true
    t.string "nit"
    t.string "legal_representative_name"
    t.string "legal_representative_document"
    t.string "legal_representative_document_type"
    t.boolean "independent", default: false, null: false
    t.bigint "referral_code_id"
    t.integer "trial_alert_stage", default: 0, null: false
    t.boolean "birthday_campaign_enabled", default: false, null: false
    t.decimal "birthday_discount_pct", precision: 5, scale: 2, default: "10.0"
    t.integer "birthday_discount_days_valid", default: 7
    t.index ["city"], name: "index_businesses_on_city"
    t.index ["independent"], name: "index_businesses_on_independent"
    t.index ["latitude", "longitude"], name: "index_businesses_on_latitude_and_longitude"
    t.index ["owner_id"], name: "index_businesses_on_owner_id"
    t.index ["referral_code_id"], name: "index_businesses_on_referral_code_id"
    t.index ["slug"], name: "index_businesses_on_slug", unique: true
    t.index ["status"], name: "index_businesses_on_status"
  end

  create_table "cash_register_closes", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "closed_by_user_id", null: false
    t.date "date", null: false
    t.datetime "closed_at"
    t.decimal "total_revenue", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_tips", precision: 12, scale: 2, default: "0.0"
    t.integer "total_appointments", default: 0
    t.text "notes"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "date"], name: "index_cash_register_closes_on_business_id_and_date", unique: true
    t.index ["business_id"], name: "index_cash_register_closes_on_business_id"
    t.index ["closed_by_user_id"], name: "index_cash_register_closes_on_closed_by_user_id"
  end

  create_table "credit_accounts", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "business_id", null: false
    t.decimal "balance", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_credit_accounts_on_business_id"
    t.index ["customer_id", "business_id"], name: "index_credit_accounts_on_customer_id_and_business_id", unique: true
    t.index ["customer_id"], name: "index_credit_accounts_on_customer_id"
  end

  create_table "credit_transactions", force: :cascade do |t|
    t.bigint "credit_account_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "transaction_type", null: false
    t.string "description"
    t.bigint "appointment_id"
    t.bigint "performed_by_user_id"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_credit_transactions_on_appointment_id"
    t.index ["credit_account_id"], name: "index_credit_transactions_on_credit_account_id"
    t.index ["performed_by_user_id"], name: "index_credit_transactions_on_performed_by_user_id"
    t.index ["transaction_type"], name: "index_credit_transactions_on_transaction_type"
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "name"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.decimal "pending_penalty", precision: 10, scale: 2, default: "0.0", null: false
    t.date "birth_date"
    t.index ["business_id", "email"], name: "index_customers_on_business_id_and_email", unique: true
    t.index ["business_id"], name: "index_customers_on_business_id"
    t.index ["email"], name: "index_customers_on_email"
  end

  create_table "discount_codes", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "code", null: false
    t.string "name"
    t.string "discount_type", default: "percentage"
    t.decimal "discount_value", precision: 10, scale: 2, null: false
    t.integer "max_uses"
    t.integer "current_uses", default: 0, null: false
    t.date "valid_from"
    t.date "valid_until"
    t.boolean "active", default: true, null: false
    t.string "source"
    t.bigint "customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "code"], name: "index_discount_codes_on_business_id_and_code", unique: true
    t.index ["business_id"], name: "index_discount_codes_on_business_id"
    t.index ["customer_id"], name: "index_discount_codes_on_customer_id"
  end

  create_table "dynamic_pricings", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "service_id"
    t.string "name", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "price_adjustment_type", default: 0
    t.integer "adjustment_mode", default: 0
    t.decimal "adjustment_value", precision: 10, scale: 2
    t.decimal "adjustment_start_value", precision: 10, scale: 2
    t.decimal "adjustment_end_value", precision: 10, scale: 2
    t.integer "days_of_week", default: [], array: true
    t.integer "status", default: 0
    t.string "suggested_by", default: "manual"
    t.text "suggestion_reason"
    t.jsonb "analysis_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "start_date", "end_date"], name: "idx_on_business_id_start_date_end_date_ec10982d08"
    t.index ["business_id", "status"], name: "index_dynamic_pricings_on_business_id_and_status"
    t.index ["business_id"], name: "index_dynamic_pricings_on_business_id"
    t.index ["service_id"], name: "index_dynamic_pricings_on_service_id"
  end

  create_table "employee_balance_adjustments", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "employee_id", null: false
    t.bigint "performed_by_user_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.decimal "balance_before", precision: 12, scale: 2
    t.decimal "balance_after", precision: 12, scale: 2
    t.string "reason", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "employee_id"], name: "idx_on_business_id_employee_id_b8c08dcc7a"
    t.index ["business_id"], name: "index_employee_balance_adjustments_on_business_id"
    t.index ["employee_id"], name: "index_employee_balance_adjustments_on_employee_id"
    t.index ["performed_by_user_id"], name: "index_employee_balance_adjustments_on_performed_by_user_id"
  end

  create_table "employee_invitations", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "business_id", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.datetime "accepted_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_employee_invitations_on_business_id"
    t.index ["employee_id"], name: "index_employee_invitations_on_employee_id"
    t.index ["token"], name: "index_employee_invitations_on_token", unique: true
  end

  create_table "employee_payments", force: :cascade do |t|
    t.bigint "cash_register_close_id", null: false
    t.bigint "employee_id", null: false
    t.integer "appointments_count", default: 0
    t.decimal "total_earned", precision: 12, scale: 2, default: "0.0"
    t.decimal "commission_pct", precision: 5, scale: 2, default: "0.0"
    t.decimal "commission_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "amount_paid", precision: 12, scale: 2, default: "0.0"
    t.integer "payment_method", default: 0
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "pending_from_previous", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_owed", precision: 12, scale: 2, default: "0.0"
    t.index ["cash_register_close_id"], name: "index_employee_payments_on_cash_register_close_id"
    t.index ["employee_id"], name: "index_employee_payments_on_employee_id"
  end

  create_table "employee_schedules", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.integer "day_of_week", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "day_of_week"], name: "index_employee_schedules_on_employee_id_and_day_of_week", unique: true
    t.index ["employee_id"], name: "index_employee_schedules_on_employee_id"
  end

  create_table "employee_services", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "service_id"], name: "index_employee_services_on_employee_id_and_service_id", unique: true
    t.index ["employee_id"], name: "index_employee_services_on_employee_id"
    t.index ["service_id"], name: "index_employee_services_on_service_id"
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "name", null: false
    t.string "photo_url"
    t.string "phone"
    t.string "email"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.text "bio"
    t.decimal "commission_percentage", precision: 5, scale: 2
    t.decimal "pending_balance", precision: 12, scale: 2, default: "0.0"
    t.string "document_number"
    t.string "document_type"
    t.string "fiscal_address"
    t.string "payment_type", default: "none", null: false
    t.decimal "fixed_daily_pay", precision: 12, scale: 2, default: "0.0"
    t.index ["business_id"], name: "index_employees_on_business_id"
    t.index ["user_id"], name: "index_employees_on_user_id"
  end

  create_table "job_configs", force: :cascade do |t|
    t.string "job_class", null: false
    t.string "name", null: false
    t.string "description"
    t.string "schedule"
    t.boolean "enabled", default: true
    t.datetime "last_run_at"
    t.string "last_run_status"
    t.text "last_run_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_class"], name: "index_job_configs_on_job_class", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "notification_event_configs", force: :cascade do |t|
    t.string "event_key", null: false
    t.string "title", null: false
    t.string "body_template"
    t.boolean "browser_notification", default: true, null: false
    t.boolean "sound_enabled", default: true, null: false
    t.boolean "in_app_notification", default: true, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_key"], name: "index_notification_event_configs_on_event_key", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "title", null: false
    t.text "body"
    t.string "notification_type", null: false
    t.string "link"
    t.boolean "read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "created_at"], name: "index_notifications_on_business_id_and_created_at"
    t.index ["business_id", "read"], name: "index_notifications_on_business_id_and_read"
    t.index ["business_id"], name: "index_notifications_on_business_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.integer "payment_method", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "proof_image_url"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reference"
    t.datetime "submitted_at"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.string "rejection_reason"
    t.index ["appointment_id"], name: "index_payments_on_appointment_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "price_monthly", precision: 10, scale: 2, null: false
    t.integer "max_employees"
    t.integer "max_services"
    t.integer "max_reservations_month"
    t.integer "max_customers"
    t.boolean "ai_features", default: false, null: false
    t.boolean "ticket_digital", default: false, null: false
    t.boolean "advanced_reports", default: false, null: false
    t.boolean "brand_customization", default: false, null: false
    t.boolean "featured_listing", default: false, null: false
    t.boolean "priority_support", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price_monthly_usd", precision: 8, scale: 2
    t.boolean "cashback_enabled", default: false, null: false
    t.decimal "cashback_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.boolean "whatsapp_notifications", default: false, null: false
  end

  create_table "referral_codes", force: :cascade do |t|
    t.string "code", null: false
    t.string "referrer_name", null: false
    t.string "referrer_email"
    t.string "referrer_phone"
    t.decimal "commission_percentage", precision: 5, scale: 2, default: "10.0"
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_referral_codes_on_code", unique: true
  end

  create_table "referrals", force: :cascade do |t|
    t.bigint "referral_code_id", null: false
    t.bigint "business_id", null: false
    t.bigint "subscription_id"
    t.integer "status", default: 0, null: false
    t.decimal "commission_amount", precision: 10, scale: 2
    t.date "activated_at"
    t.date "paid_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_referrals_on_business_id"
    t.index ["referral_code_id", "business_id"], name: "index_referrals_on_referral_code_id_and_business_id", unique: true
    t.index ["referral_code_id"], name: "index_referrals_on_referral_code_id"
    t.index ["subscription_id"], name: "index_referrals_on_subscription_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "request_logs", force: :cascade do |t|
    t.bigint "business_id"
    t.string "method", null: false
    t.string "path", null: false
    t.string "controller_action"
    t.integer "status_code"
    t.float "duration_ms"
    t.string "ip_address"
    t.string "user_agent"
    t.jsonb "request_params", default: {}
    t.jsonb "response_body", default: {}
    t.text "error_message"
    t.text "error_backtrace"
    t.string "request_id"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "created_at"], name: "index_request_logs_on_business_id_and_created_at"
    t.index ["business_id"], name: "index_request_logs_on_business_id"
    t.index ["created_at"], name: "index_request_logs_on_created_at"
    t.index ["request_id"], name: "index_request_logs_on_request_id"
    t.index ["resource_type", "resource_id"], name: "index_request_logs_on_resource_type_and_resource_id"
    t.index ["status_code"], name: "index_request_logs_on_status_code"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "customer_id"
    t.string "customer_name"
    t.integer "rating", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "appointment_id"
    t.bigint "employee_id"
    t.index ["appointment_id"], name: "index_reviews_on_appointment_id"
    t.index ["business_id"], name: "index_reviews_on_business_id"
    t.index ["customer_id"], name: "index_reviews_on_customer_id"
    t.index ["employee_id"], name: "index_reviews_on_employee_id"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "duration_minutes", null: false
    t.boolean "active", default: true, null: false
    t.string "category"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_services_on_business_id"
  end

  create_table "site_configs", force: :cascade do |t|
    t.string "key", null: false
    t.text "value", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_site_configs_on_key", unique: true
  end

  create_table "subscription_payment_orders", force: :cascade do |t|
    t.bigint "subscription_id"
    t.bigint "business_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "due_date", null: false
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.string "status", default: "pending"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "plan_id"
    t.datetime "proof_submitted_at"
    t.string "reviewed_by"
    t.datetime "reviewed_at"
    t.index ["business_id", "status"], name: "index_subscription_payment_orders_on_business_id_and_status"
    t.index ["business_id"], name: "index_subscription_payment_orders_on_business_id"
    t.index ["due_date"], name: "index_subscription_payment_orders_on_due_date"
    t.index ["plan_id"], name: "index_subscription_payment_orders_on_plan_id"
    t.index ["subscription_id"], name: "index_subscription_payment_orders_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "plan_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "expiry_alert_stage", default: 0, null: false
    t.index ["business_id"], name: "index_subscriptions_on_business_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "name"
    t.integer "role", default: 0, null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_url"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "businesses"
  add_foreign_key "appointment_services", "appointments"
  add_foreign_key "appointment_services", "services"
  add_foreign_key "appointments", "businesses"
  add_foreign_key "appointments", "customers"
  add_foreign_key "appointments", "discount_codes"
  add_foreign_key "appointments", "dynamic_pricings"
  add_foreign_key "appointments", "employees"
  add_foreign_key "appointments", "services"
  add_foreign_key "blocked_slots", "businesses"
  add_foreign_key "blocked_slots", "employees"
  add_foreign_key "business_goals", "businesses"
  add_foreign_key "business_hours", "businesses"
  add_foreign_key "businesses", "referral_codes"
  add_foreign_key "businesses", "users", column: "owner_id"
  add_foreign_key "cash_register_closes", "businesses"
  add_foreign_key "cash_register_closes", "users", column: "closed_by_user_id"
  add_foreign_key "credit_accounts", "businesses"
  add_foreign_key "credit_accounts", "customers"
  add_foreign_key "credit_transactions", "appointments"
  add_foreign_key "credit_transactions", "credit_accounts"
  add_foreign_key "credit_transactions", "users", column: "performed_by_user_id"
  add_foreign_key "customers", "businesses"
  add_foreign_key "discount_codes", "businesses"
  add_foreign_key "discount_codes", "customers"
  add_foreign_key "dynamic_pricings", "businesses"
  add_foreign_key "dynamic_pricings", "services"
  add_foreign_key "employee_balance_adjustments", "businesses"
  add_foreign_key "employee_balance_adjustments", "employees"
  add_foreign_key "employee_balance_adjustments", "users", column: "performed_by_user_id"
  add_foreign_key "employee_invitations", "businesses"
  add_foreign_key "employee_invitations", "employees"
  add_foreign_key "employee_payments", "cash_register_closes"
  add_foreign_key "employee_payments", "employees"
  add_foreign_key "employee_schedules", "employees"
  add_foreign_key "employee_services", "employees"
  add_foreign_key "employee_services", "services"
  add_foreign_key "employees", "businesses"
  add_foreign_key "employees", "users"
  add_foreign_key "notifications", "businesses"
  add_foreign_key "payments", "appointments"
  add_foreign_key "referrals", "businesses"
  add_foreign_key "referrals", "referral_codes"
  add_foreign_key "referrals", "subscriptions"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "request_logs", "businesses"
  add_foreign_key "reviews", "appointments"
  add_foreign_key "reviews", "businesses"
  add_foreign_key "reviews", "customers"
  add_foreign_key "reviews", "employees"
  add_foreign_key "services", "businesses"
  add_foreign_key "subscription_payment_orders", "businesses"
  add_foreign_key "subscription_payment_orders", "plans"
  add_foreign_key "subscription_payment_orders", "subscriptions"
  add_foreign_key "subscriptions", "businesses"
  add_foreign_key "subscriptions", "plans"
end
