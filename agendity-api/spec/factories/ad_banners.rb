FactoryBot.define do
  factory :ad_banner do
    name { "Test Banner" }
    placement { "dashboard_top" }
    active { true }
    priority { 0 }
    impressions_count { 0 }
    clicks_count { 0 }
  end
end
