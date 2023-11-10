require_relative '../common/utils.rb'
require_relative '../locations/import_universities.rb'

namespace :import do
  desc 'Import Locations from CSV'
  task :locations, [:file_name, :create_regions, :contests] => [:environment] do |task, args|
    if Utils.valid_file?(file_name: args[:file_name])
      puts args
      ImportLocations.import_from_csv(file_name: args[:file_name], 
                                      create_regions: args[:create_regions],
                                      contests: args[:contests])
    end
  end
end
