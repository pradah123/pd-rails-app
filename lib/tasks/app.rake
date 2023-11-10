require_relative '../taxonomy/taxonomy_file_process.rb'
require_relative '../common/utils.rb'
require_relative '../common/file_operations.rb'
require_relative '../common/aws_operations.rb'

namespace :jobs do
  desc 'Schedule ObservationsFetchJob job'
  task schedule: :environment do
    ObservationsFetchJob.perform_later
    FetchObservationOrgUsernameJob.perform_later
  end  
end

namespace :statistics do
  desc 'Schedule Reset Statistics'
  task reset: :environment do
    ## Reset statistics
    Region.all.each do |r|
      puts "Before #{r.id} #{Time.now}"
      #{}next if (r.id != 784)
      r.reset_statistics
      puts "After #{r.id} #{Time.now}"
    end
    # Participation.all.each do |p|
    #   p.reset_statistics
    # end
    Contest.all.each { |c| c.reset_statistics }
  end
end

namespace :taxonomy do
  desc 'Store Taxonomy'
  task :store, [:file_name, :read_from_last_processed] => [:environment] do |task, args|
    if Utils.valid_file?(file_name: args[:file_name])
      TaxonomyFileProcess.process_file(file_name: args[:file_name],
                                       read_from_last_processed: args[:read_from_last_processed])
    else
      Rails.logger.info ">>> taxonomy:store::Invalid file #{args[:file_name]}"
    end
  end

  desc 'Update Taxonomy to Observations'
  task :update, [:update_all, :from_date] => [:environment] do |task, args|
    Observation.update_observations_taxonomy(update_all: args[:update_all], from_date: args[:from_date])
  end
end

namespace :participation_species_matview do
  desc 'Update participation_species_matview'
  task refresh: :environment do
    ParticipationSpeciesMatview.refresh
  end
end

namespace :participation_observer_species_matview do
  desc 'Update participation_observer_species_matview'
  task refresh: :environment do
    ParticipationObserverSpeciesMatview.refresh
  end
end

namespace :add_data_source_gbif do
  desc 'Add data_source gbif to all the participations'
  task participations: :environment do
    participations = Participation.where(status: 'accepted')
    participations.each do |p|
      data_sources = p.data_sources
      data_sources.push(DataSource.find_by_name('gbif'))
      p.data_sources = data_sources
      p.save
    end
  end
end

namespace :remove_data_source_gbif do
  desc 'Remove data_source gbif from all the participations'
  task participations: :environment do
    # participations = Participation.where(status: 'accepted')
    Participation.all.each do |p|
      data_sources = p.data_sources
      data_sources = p.data_sources.map {|ds|
        ds.name == 'gbif' ? nil : ds
      }.compact
      p.data_sources = data_sources
      p.save
    end
  end
end


namespace :subregions do
  desc 'Create sub regions for all the regions'
  task create: :environment do
    Region.all.each do |r|
      r.compute_subregions
    end
  end
end

namespace :regions_observations_matview do
  desc 'Update regions_observations_matview'
  task refresh: :environment do
    RegionsObservationsMatview.refresh
  end
end

namespace :species_grouped_by_day_matview do
  desc 'Update species_grouped_by_day_matview'
  task refresh: :environment do
    SpeciesGroupedByDayMatview.refresh
  end
end

namespace :observer_species_grouped_by_day_matview do
  desc 'Update observer_species_grouped_by_day_matview'
  task refresh: :environment do
    ObserverSpeciesGroupedByDayMatview.refresh
  end
end

namespace :species_matview do
  desc 'Update species_matview'
  task refresh: :environment do
    SpeciesMatview.refresh
  end
end

namespace :species_by_regions_matview do
  desc 'Update species_by_regions_matview'
  task refresh: :environment do
    SpeciesByRegionsMatview.refresh
  end
end

namespace :total_observations_metrics_matview do
  desc 'Update total_observations_metrics_matview'
  task refresh: :environment do
    TotalObservationsMetricsMatview.refresh
  end
end

namespace :taxon_observations_monthly_count_matview do
  desc 'Update taxon_observations_monthly_count_matview'
  task refresh: :environment do
    TaxonObservationsMonthlyCountMatview.refresh
  end
end


namespace :calculate do
  desc 'Calculate area of each region polygon and total area of all regions in each contest'
  task region_and_contest_area: :environment do
    regions = Region.where(base_region_id: nil)
    regions.each do |r|
      json = JSON.parse r.raw_polygon_json
      next if json.nil?
      area = 0
      json.each do |polygon|
        area += Utils.calculate_polygon_area(polygon['coordinates'])
      end
      r.set_polygon_area(area.round(2))
      Rails.logger.info "Region name: #{r.name}, Area: #{area}"
    end

    contests = Contest.all
    contests.each do |c|
      contest_area = 0
      contest_area = c.regions&.sum(:polygon_area)
      c.update_total_area(contest_area.round(2))
      Rails.logger.info "Contest name: #{c.title}, Area: #{contest_area.round(2)}"
    end
  end
end

namespace :download do
  desc "Download and save the image"
  task image: :environment do
    file_name = "region-1-logo"
    url = "https://wayanad.org/wp-content/uploads/2021/01/PHOTO-2020-10-07-21-33-03-4-1.jpg"
    file_path = FileOperations.download_image(file_name, url)
    client = AWSOperations.get_s3_client
    puts client
    if client
      puts "Inside client: #{file_path}"
      AWSOperations.aws_s3_file_upload(client, file_path, "region-logos/" )
    end
    # FileOperations.save_thumbnail_image(file_path, "#{file_name}_thumbnail")
  end
end
