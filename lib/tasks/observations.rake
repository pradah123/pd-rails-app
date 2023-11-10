require_relative '../sightings/sightings.rb'

namespace :inaturalist_sightings do
  desc "Update inaturalist sightings"
  task :update, [:from_date, :to_date, :days] => [:environment] do |task, args|
    Rails.logger.info("inaturalist_sightings::processes running")
    Rails.logger.info(`ps aux | pgrep -f inaturalist_sightings:update`)
    status = `ps aux | pgrep -f inaturalist_sightings:update | tail -n +5`
    Rails.logger.info("inaturalist_sightings::process running? :#{status}")
    if status == ""
      Sightings.update_inaturalist_sightings(args[:from_date], args[:to_date], args[:days])
    else
      Rails.logger.info("inaturalist_sightings::update task is already running")
    end
  end
end

namespace :questa_civilizations_json do
  desc "Generate json file from questagame civilizations"
  task create: :environment do
    Sightings.generate_questa_civilizations_json()
  end
end


namespace :civilization_for_old_sightings do
  desc "Update civilization data for old sightings"
  task :update, [:days] => [:environment] do |task, args|
    Rails.logger.info("civilization_for_old_sightings::processes running")
    Rails.logger.info(`ps aux | pgrep -f civilization_for_old_sightings:update`)
    status = `ps aux | pgrep -f civilization_for_old_sightings:update | tail -n +5`
    Rails.logger.info("civilization_for_old_sightings::process running? :#{status}")
    if status == ""
      Sightings.update_civilization_for_old_sightings(args[:days])
    else
      Rails.logger.info("civilization_for_old_sightings::update task is already running")
    end
  end
end
