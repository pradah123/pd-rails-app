class ObservationsFetchJob < ApplicationJob
  queue_as :queue_observations_fetch

  before_enqueue do |job|
    # If jobs are already running then avoid starting new ObservationsFetchJob
    # Exclude taxonomy update job from this check, as it is being run separately
    # and not along with observations fetch/create cycle
    if Delayed::Job.where("locked_by is not null and failed_at is null and queue != 'observations_#{Rails.env}_queue_taxonomy_update'").count.positive?
      Delayed::Worker.logger.info ">>>>>>>>>> Other delayed job is already running, hence exiting, job count #{Delayed::Job.where('locked_by is not null and failed_at is null').count}"
      exit(0)
    end
  end

  def perform
    Delayed::Worker.logger.info "\n\n\n\n"
    Delayed::Worker.logger.info ">>>>>>>>>> ObservationsFetchJob fetching observations"
    regions = []
    regions = Region.get_regions_for_data_fetching()

    r_hash = []
    r_hash = Region.get_data_sources_and_date_range_for_data_fetch(regions: regions)

    r_hash.each do |r|
      r[:data_sources].each do |data_source|
        next unless data_source.present?

        ds_obj = data_source[:data_source]
        region_obj = r[:region]
        start_dt = data_source[:starts_at]
        end_dt = data_source[:ends_at]
        Delayed::Worker.logger.info ">>>>>>>>>>>>>>>>>>>>> ObservationsFetchJob fetching data for region: #{region_obj.name}, data_source: #{ds_obj.name}, starts_at: #{start_dt}"

        if data_source[:data_source].name == 'gbif'
          GbifObservationsFetchJob.perform_later(start_dt: start_dt, end_dt: end_dt, greater_region_id: region_obj.id)
        else
          ds_obj.fetch_observations region_obj, start_dt, end_dt
        end
      end
    end

    Delayed::Worker.logger.info ">>>>>>>>>> ObservationsFetchJob completed\n\n\n\n"
  end

end
