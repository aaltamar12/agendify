# frozen_string_literal: true

# Rails generators configuration.
# Skips unnecessary files and uses factory_bot for test data.

Rails.application.config.generators do |g|
  g.helper false
  g.view_specs false
  g.routing_specs false
  g.helper_specs false
  g.request_specs true
  g.test_framework :rspec, fixture: false
  g.fixture_replacement :factory_bot, dir: "spec/factories"
end
