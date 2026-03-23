# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  # ActiveAdmin panel
  ActiveAdmin.routes(self)

  # Sidekiq Web UI — authenticated behind ActiveAdmin session
  Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
    admin = AdminUser.find_by(email: username)
    admin&.valid_password?(password)
  end
  mount Sidekiq::Web => "/admin/sidekiq"

  # Admin session-based authentication (separate from API JWT auth)
  get  "admin/login",  to: "admin/sessions#new",     as: :admin_login
  post "admin/login",  to: "admin/sessions#create",  as: :admin_create_session
  get  "admin/logout", to: "admin/sessions#destroy", as: :admin_logout

  # Health check for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Auth
      post "auth/login",            to: "auth#login"
      post "auth/register",         to: "auth#register"
      post "auth/refresh",          to: "auth#refresh"
      get  "auth/me",               to: "auth#me"
      delete "auth/logout",         to: "auth#logout"
      post "auth/forgot_password",  to: "passwords#forgot_password"
      post "auth/reset_password",   to: "passwords#reset_password"

      # Business (singular resource — current user's business)
      resource :business, only: %i[show update] do
        post :upload_logo, on: :member
        post :upload_cover, on: :member
        get  :cover_gallery, on: :member
        post :select_cover, on: :member
        post :onboarding, on: :member
      end

      # Resources scoped to business
      resources :services
      resources :employees do
        member do
          post :upload_avatar
          post :invite
          post :adjust_balance
          get :balance_history
        end
      end

      # Employee invitations (public — no auth)
      resources :employee_invitations, only: [:show], param: :token do
        post :accept, on: :member
      end
      resources :customers, only: %i[index show] do
        member do
          get :credits, to: "credits#show"
          post "credits/adjust", to: "credits#adjust"
          get :credit_balance, to: "credits#balance"
        end
      end

      # Credits
      get "credits/summary", to: "credits#summary"
      post "credits/bulk_adjust", to: "credits#bulk_adjust"

      resources :appointments do
        collection do
          post :checkin_by_code
          get :available_slots
        end
        member do
          post :confirm
          post :checkin
          post :cancel
          post :complete
          post :remind_payment
        end
      end

      # Payments on appointments
      post "appointments/:appointment_id/payments/submit", to: "payments#submit"

      resources :payments, only: [] do
        member do
          post :approve
          post :reject
        end
      end

      resources :notifications, only: [:index] do
        post :mark_read, on: :member
        collection do
          post :mark_all_read
          get :unread_count
        end
      end

      resources :reviews, only: %i[index]

      resource :business_hours, only: %i[show update]
      resources :blocked_slots, only: %i[index show create update destroy]

      # Goals (Plan Inteligente)
      resources :goals, except: [:new, :edit] do
        get :progress, on: :collection
      end

      # Dynamic pricing
      resources :dynamic_pricing, except: [:new, :edit] do
        member do
          patch :accept
          patch :reject
        end
      end

      # Subscription checkout
      scope :subscription, controller: "subscription_checkout" do
        get :plans
        get :payment_info
        post :checkout
        get :status
      end

      # Employee portal
      namespace :employee do
        get :dashboard, to: "dashboard#show"
        get :score, to: "dashboard#score"
        resources :appointments, only: [:index] do
          post :checkin, on: :member
        end
      end

      # Cash register
      resources :cash_register, only: [:show] do
        collection do
          get :today
          post :close
          get :history
          post :upload_proof
          delete :delete_proof
        end
      end

      # Reconciliation
      get "reconciliation/check", to: "reconciliation#check"

      # Reports
      get "reports/summary",            to: "reports#summary"
      get "reports/revenue",            to: "reports#revenue"
      get "reports/top_services",       to: "reports#top_services"
      get "reports/top_employees",      to: "reports#top_employees"
      get "reports/frequent_customers", to: "reports#frequent_customers"
      get "reports/profit",              to: "reports#profit"

      # QR
      post "qr/generate", to: "qr#generate"

      # Admin endpoints (superadmin only)
      namespace :admin do
        get  "businesses", to: "businesses#index"
        post "impersonate", to: "impersonation#create"
        post "stop_impersonation", to: "impersonation#destroy"
      end

      # Notification config (public, no auth required)
      get "notification_config", to: "notification_config#index"

      # Locations (no auth required)
      get "locations/countries", to: "locations#countries"
      get "locations/states",   to: "locations#states"
      get "locations/cities",   to: "locations#cities"

      # Public endpoints (no auth required)
      namespace :public do
        # Referral code validation
        get "referral_codes/:code/validate", to: "referral_codes#validate"

        # Platform config (contact info, payment data)
        get "site_config", to: "site_config#show"

        # Static routes first (before :slug catch-all)
        get  "ad_banners",                   to: "ad_banners#index"
        post "ad_banners/:id/impression",    to: "ad_banners#impression"
        post "ad_banners/:id/click",         to: "ad_banners#click"
        get  "tickets/:code",                to: "tickets#show"
        get  "tickets/:code/cancel_preview",  to: "tickets#cancel_preview"
        post "tickets/:code/cancel",          to: "tickets#cancel"
        post "tickets/:code/payment",         to: "tickets#submit_payment"
        get  "explore",            to: "explore#index"
        # Slug-based routes (frontend uses /api/v1/public/:slug)
        get  "customer_lookup",    to: "bookings#customer_lookup"
        get  "cities",             to: "explore#cities"
        get  ":slug",              to: "businesses#show"
        get  ":slug/availability",    to: "businesses#availability"
        get  ":slug/price_preview",   to: "businesses#price_preview"
        get  ":slug/price_calendar",  to: "businesses#price_calendar"
        get  ":slug/check_slot",   to: "bookings#check_slot"
        post ":slug/book",         to: "bookings#create"
        post ":slug/lock_slot",    to: "bookings#lock_slot"
        post ":slug/unlock_slot",  to: "bookings#unlock_slot"
      end
    end
  end
end
