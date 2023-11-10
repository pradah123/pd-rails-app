namespace :update_gbif_observations_matview do
  desc 'Update the GBIF Observations materialized view'
  task refresh: :environment do
    GbifObservationsMatview.refresh
  end
end

namespace :gbif_observations_common_name do
  desc "Update the GBIF Observations' common_name with vernacularName"
  task :update, [:file_name] => [:environment] do |task, args|
    if Utils.valid_file?(file_name: args[:file_name])
      TaxonomyFileProcess.taxonomy_vernacular_file_process(file_name: args[:file_name])
    else
      Rails.logger.info ">>> taxonomy:store::Invalid file #{args[:file_name]}"
    end
  end
end
