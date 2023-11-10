#!/usr/bin/env puma

rails_env = ENV.fetch("RAILS_ENV", "development")

dir_path = "."

directory dir_path
rackup "#{dir_path}/config.ru"
environment rails_env

tag ''

pidfile "#{dir_path}/tmp/pids/puma.pid"
state_path "#{dir_path}/tmp/pids/puma.state"
stdout_redirect "#{dir_path}/log/puma_access.log", "#{dir_path}/log/puma_error.log", true
worker_timeout 3600 if rails_env == "development"

workers ENV.fetch("WEB_CONCURRENCY") { 2 }
port ENV.fetch("PORT") { 3000 }

# max_threads_count = (rails_env == "development" ? 1 : ENV.fetch("RAILS_MAX_THREADS"))
# min_threads_count = (rails_env == "development" ? 1 : ENV.fetch("RAILS_MIN_THREADS"))
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") {5}
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count } 
threads min_threads_count, max_threads_count

preload_app!
rackup      DefaultRackup

bind "unix://#{dir_path}/tmp/sockets/puma.sock"

restart_command 'bundle exec puma'

prune_bundler

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end

on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = ""
end
