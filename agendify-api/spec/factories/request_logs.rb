FactoryBot.define do
  factory :request_log do
    association :business
    add_attribute(:method) { "GET" }
    path { "/api/v1/appointments" }
    controller_action { "appointments#index" }
    status_code { 200 }
    duration_ms { 42.5 }
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0" }
    request_params { {} }
    request_id { SecureRandom.uuid }

    trait :error do
      status_code { 422 }
      error_message { "Validation failed" }
    end

    trait :server_error do
      status_code { 500 }
      error_message { "Internal server error" }
      error_backtrace { "app/controllers/api/v1/appointments_controller.rb:10\napp/services/base_service.rb:5" }
    end

    trait :with_resource do
      resource_type { "Appointment" }
      resource_id { 1 }
    end

    trait :public_request do
      business { nil }
      path { "/api/v1/public/barberia-elite/book" }
      controller_action { "public/bookings#create" }
    end
  end
end
