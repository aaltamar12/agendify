FactoryBot.define do
  factory :admin_notification do
    title { "Test Admin Notification" }
    body { "Something happened" }
    notification_type { "alert" }
    read { false }
  end
end
