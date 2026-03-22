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

ActiveRecord::Schema[8.0].define(version: 2026_03_22_000006) do
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
    t.index ["business_id", "appointment_date", "status"], name: "idx_appointments_biz_date_status"
    t.index ["business_id"], name: "index_appointments_on_business_id"
    t.index ["customer_id"], name: "index_appointments_on_customer_id"
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
    t.index ["city"], name: "index_businesses_on_city"
    t.index ["latitude", "longitude"], name: "index_businesses_on_latitude_and_longitude"
    t.index ["owner_id"], name: "index_businesses_on_owner_id"
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

  create_table "customers", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "name"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.decimal "pending_penalty", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["business_id", "email"], name: "index_customers_on_business_id_and_email", unique: true
    t.index ["business_id"], name: "index_customers_on_business_id"
    t.index ["email"], name: "index_customers_on_email"
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
    t.index ["business_id"], name: "index_employees_on_business_id"
    t.index ["user_id"], name: "index_employees_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
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

  create_table "subscription_payment_orders", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.bigint "business_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "due_date", null: false
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.string "status", default: "pending"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "status"], name: "index_subscription_payment_orders_on_business_id_and_status"
    t.index ["business_id"], name: "index_subscription_payment_orders_on_business_id"
    t.index ["due_date"], name: "index_subscription_payment_orders_on_due_date"
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
  add_foreign_key "appointments", "businesses"
  add_foreign_key "appointments", "customers"
  add_foreign_key "appointments", "employees"
  add_foreign_key "appointments", "services"
  add_foreign_key "blocked_slots", "businesses"
  add_foreign_key "blocked_slots", "employees"
  add_foreign_key "business_hours", "businesses"
  add_foreign_key "businesses", "users", column: "owner_id"
  add_foreign_key "cash_register_closes", "businesses"
  add_foreign_key "cash_register_closes", "users", column: "closed_by_user_id"
  add_foreign_key "customers", "businesses"
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
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "request_logs", "businesses"
  add_foreign_key "reviews", "appointments"
  add_foreign_key "reviews", "businesses"
  add_foreign_key "reviews", "customers"
  add_foreign_key "reviews", "employees"
  add_foreign_key "services", "businesses"
  add_foreign_key "subscription_payment_orders", "businesses"
  add_foreign_key "subscription_payment_orders", "subscriptions"
  add_foreign_key "subscriptions", "businesses"
  add_foreign_key "subscriptions", "plans"
end
