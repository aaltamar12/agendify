require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "sprockets/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AgendityApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Use Sidekiq for background job processing
    config.active_job.queue_adapter = :sidekiq

    # Active Record Encryption keys for encrypting sensitive fields at rest.
    # In production, set these via environment variables with secure random values.
    config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", "dev-primary-key-change-in-prod-32ch")
    config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", "dev-deterministic-key-change-32ch")
    config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", "dev-salt-change-in-production-32c")
    # Allow reading both encrypted and unencrypted data during migration period
    config.active_record.encryption.support_unencrypted_data = true

    # NOT using config.api_only = true because ActiveAdmin needs full Rails
    # (sessions, cookies, flash, helpers, asset pipeline).
    # Instead, ApplicationController inherits from ActionController::API
    # to keep all API controllers lightweight. ActiveAdmin uses
    # ActionController::Base via InheritedResources automatically.

    # Generate API-style controllers by default
    config.generators.api_only = true
  end
end
