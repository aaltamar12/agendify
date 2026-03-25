FactoryBot.define do
  factory :notification_event_config do
    sequence(:event_key) { |n| "test_event_#{n}" }
    title { "Test Event" }
    body_template { "Something happened: {{detail}}" }
    browser_notification { true }
    sound_enabled { true }
    in_app_notification { true }
    active { true }
  end
end
