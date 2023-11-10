class TaxonomyUpdateJob < ApplicationJob
  queue_as :queue_taxonomy_update

  def perform(scientific_name:)
    Delayed::Worker.logger.info "\n\n\n\n"
    Delayed::Worker.logger.info ">>>>>>>>>> TaxonomyUpdateJob updating taxonomy to observations"
    
    Observation.update_taxonomy(scientific_name: scientific_name)

    Delayed::Worker.logger.info ">>>>>>>>>>TaxonomyUpdateJob completed\n\n\n\n"
  end

end
