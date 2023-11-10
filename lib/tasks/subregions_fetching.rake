#
#  this rake task should be run once every fifteen minutes,
#  starting on the hour
#

namespace :subregions_fetching do
  desc 'create subregions fetching jobs'
  task schedule: :environment do
    Subregion.each do |s|
      s.data_source.fetch_and_store_observations.perform_later
    end  
  end
end

