namespace :assets do
  desc 'Compile assets'
  task :compile do
    on roles(:app), :except => { :no_release => true } do
      within "#{fetch(:deploy_to)}/current/" do
        with RAILS_ENV: fetch(:environment) do
          execute :rails, "assets:clobber assets:precompile"
        end
      end
    end
  end
end
