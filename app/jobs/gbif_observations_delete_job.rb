require_relative '../../lib/delayed_jobs/helpers/status.rb'

class GbifObservationsDeleteJob < ApplicationJob
  queue_as :queue_gbif_observations_delete

  def perform(region_id: nil)
    Delayed::Worker.logger.info "\n\n\n\n"
    Delayed::Worker.logger.info ">>>>>>>>>> GbifObservationsDeleteJob Deleting unwanted observations for region '#{region_id}'"
    while JobStatus.job_is_running?(exclude: 'observations_gbif_delete_job')
      Delayed::Worker.logger.info "GbifObservationsDeleteJob: Waiting for other jobs to complete"
      sleep 60
    end
    if region_id.present?
      Observation.delete_unwanted_observations_from_region(region_id: region_id)
    end
    
    Delayed::Worker.logger.info ">>>>>>>>>> GbifObservationsDeleteJob completed\n\n\n\n"
  end

end
