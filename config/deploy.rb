# config valid for current version and patch releases of Capistrano
lock "~> 3.17.0"

set :repo_url, "https://gitlab.com/earthguardians1/biosmart-api.git"

set :branch, ->{ fetch(:branch) }

set :rvm_custom_path, '/usr/share/rvm'
set :rvm_map_bins, fetch(:rvm_map_bins, []).push('rails')

# Default value for :linked_files is []
append :linked_files, "config/database.yml", 'config/master.key', '.env', 'config/puma.rb'

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage", "public/packs", ".bundle", "node_modules"

# Default value for local_user is ENV['USER']
set :local_user, "ubuntu"

set :migration_role, :app

set :keep_releases, 2

# Uncomment the following to require manually verifying the host key before first deploy.
set :ssh_options, verify_host_key: :always

set :pty, true
set :ssh_options, {
  forward_agent: true,
  auth_methods: ["publickey"]
}

namespace :delayed_job do
	desc "Restart delayed jobs"
	task :restart do
		on roles(:app) do |host|
			within "#{current_path}" do
				with RAILS_ENV: fetch(:rails_env) do
					execute :sudo, :service, :delayed_job, :restart
				end
			end
		end
	end
end

namespace :setup do
  desc 'installs required libraries'
  task :libraries do
    on roles(:app), in: :sequence do
      execute :sudo, "apt-get -y install imagemagick"
    end
  end
end

after 'deploy:symlink:release', 'assets:compile'
after 'assets:compile', 'setup:libraries'
after 'puma:restart', 'deploy:restart'
after 'puma:restart', 'delayed_job:restart'
