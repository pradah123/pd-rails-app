class ObservationsFetchAllJob < ApplicationJob
  queue_as :queue_observations_fetch_all

  def perform
    Delayed::Worker.logger.info "\n\n\n\n"
    Delayed::Worker.logger.info ">>>>>>>>>> ObservationsFetchAllJob fetching observations"
    
    regions = []

    regions = Region.get_regions_for_data_fetching()
    
    r_hash = []
    r_hash = Region.get_data_sources_and_date_range_for_data_fetch(regions: regions)

    r_hash.each do |r|
      r[:data_sources].each do |data_source|
        Delayed::Worker.logger.info ">>>>>>>>>>>>>>>>>>>>> Fetching data for region: #{r[:region].name}, data_source: #{data_source[:data_source].name}, starts_at: #{data_source[:starts_at]}"
        data_source[:data_source].fetch_observations r[:region], data_source[:starts_at], data_source[:ends_at]
      end
    end

    Delayed::Worker.logger.info ">>>>>>>>>>ObservationsFetchAllJob completed\n\n\n\n"
  end

end
