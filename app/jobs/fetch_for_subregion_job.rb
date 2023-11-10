class FetchForSubregionJob < ApplicationJob
  
  #   
  # this job will fetch the data for this subregion
  #
  # it is created from the rake task /lib/tasks/subregions_fetching.rake
  #
  # please reference that file for more details
  #

  def perform subregion_id
    minute = Time.now.min
    hour = Time.now.hour

    Delayed::Worker.logger.info ">>>>>>>>>> processing subregion #{subregion_id} at hour = #{hour} minute = #{minute}"
    
    subregion = Subregion.find_by_id subregion_id

    if subregion.nil?
      Delayed::Worker.logger.info "  subregion #{subregion_id} does not exist"

    elsif subregion.processing?
      Delayed::Worker.logger.info "  subregion #{subregion_id} already processing"
    
    elsif subregion.should_fetch_now(hour, min)==false
      Delayed::Worker.logger.info "  subregion #{subregion_id} not scheduled to fetch at this time"
    
    else  
      Delayed::Worker.logger.info "  subregion #{subregion_id} in #{subregion.region.name} processing"
      subregion.fetch_and_store_observations
    
    end

    Delayed::Worker.logger.info ">>>>>>>>>> completed processing subregion #{subregion_id}"
  end
end
