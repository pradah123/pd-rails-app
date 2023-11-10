class GbifObservationsFetchJob < ApplicationJob
  queue_as :queue_gbif_observations_fetch

  def perform (start_dt: nil, end_dt: nil, greater_region_id: nil, split_dates: true)
    Delayed::Worker.logger.info ">>>>>>>>>>>>>>>>>>>>> GbifObservationsFetchJob fetching observations"
    greater_regions = []
    if greater_region_id.present?
      greater_regions = Region.where(id: greater_region_id)
    end
    greater_regions.each do |region|
      data_source = DataSource.find_by_name('gbif')

      starts_at = ends_at = nil

      if start_dt.nil? || end_dt.nil? ## Evaluate start and end dates only if are not given
        ends_at = Time.now()
        latest_observation = Observation.get_observations_for_region(region_id: region.id, include_gbif: true).order("observed_at").last

        ## If there are observations exist for the region then fetch data from the latest observed at date till now
        ## else fetch 3 years back data(as it can be a new region)
        if latest_observation&.observed_at.present?
          starts_at = latest_observation.observed_at
        else
          starts_at = ends_at - Utils.convert_to_seconds(unit:'year', value: 3)
        end
      else
        starts_at = start_dt.to_time
        ends_at = end_dt.to_time
      end
      total_count = data_source.fetch_gbif_observations_count region, starts_at, ends_at
      Delayed::Worker.logger.info "Total gbif observations count for region (#{region.name} - #{region.id}) and date range #{starts_at} - #{ends_at}: #{total_count}"

      if total_count > 10000 && split_dates.present?
        ## If total records exceed 10k, split the date range monthwise and fetch the data for each month seperately
        (DateTime.parse(starts_at.strftime("%Y-%m-%d"))..DateTime.parse(ends_at.strftime("%Y-%m-%d"))).
        group_by {|arr| [arr.year, arr.month]}.map do |group|
          ## Each group represent a month with dates, we need to pick first and last date
          GbifObservationsFetchJob.perform_later  start_dt: group.last.first,
                                                  end_dt: group.last.last,
                                                  greater_region_id: region.id,
                                                  split_dates: false
        end
      else
        Delayed::Worker.logger.info "Fetching data for : #{region.name}, #{starts_at}. #{ends_at}"
        data_source.fetch_observations region, starts_at, ends_at
      end
    end

    Delayed::Worker.logger.info ">>>>>>>>>> completed\n\n\n\n"
  end

end
