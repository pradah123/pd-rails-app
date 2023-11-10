require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Biosmart
  class Application < Rails::Application
    #config.load_defaults 6.1
    config.hosts << "localhost"
    config.hosts << "portal.biosmart.life"
    config.hosts << "portal-staging.biosmart.life"

    config.assets.compile = true
    config.assets.precompile =  ['*.js', '*.css'] 
    config.assets.paths << Rails.root.join("app", "assets", "javascripts")
    config.assets.paths << Rails.root.join("app", "assets", "stylesheets")

    config.action_controller.forgery_protection_origin_check = false
    config.middleware.use ActionDispatch::Cookies
    config.action_dispatch.cookies_same_site_protection = :strict

    config.active_job.queue_adapter = :delayed_job
    config.active_job.queue_name_prefix = "observations_#{Rails.env}"

    config.active_record.legacy_connection_handling = false

    #config.middleware.insert_before 0, Rack::Cors do
    #  allow do
    #    origins '*'
    #    resource '*', :headers => :any, :methods => [:get, :post, :options]
    #  end
    #end
    
    #config.action_mailer.delivery_method = :smtp
    #config.action_mailer.smtp_settings = {
    #  :address              => Rails.application.credentials.email_address,
    #  :port                 => 587,
    #  :user_name            => Rails.application.credentials.email_username,
    #  :password             => Rails.application.credentials.email_password,
    #  :authentication       => "plain",
    #  :enable_starttls_auto => true
    #}
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
