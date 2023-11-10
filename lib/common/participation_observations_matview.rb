class ParticipationObservationsMatview < ActiveRecord::Base
  self.table_name = 'participation_observations_matview'
  scope :recent, -> { order observed_at: :desc }

  scope :has_scientific_name, -> { where.not scientific_name: @@filtered_scientific_names }
  scope :has_accepted_name, -> { where.not accepted_name: @@filtered_scientific_names }
  scope :from_observation_org, -> { joins(:data_source).where(data_sources: { name: 'observation.org' }) }
  scope :ignore_species_code, -> { where('accepted_name != lower(accepted_name)') }
  scope :has_creator_id, -> { where.not creator_id: nil }
  scope :without_creator_name, -> { where creator_name: nil }
  scope :has_images, -> { where.not url: nil }

  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens']


  def readonly?
    true
  end

  def self.get_species_details(participation_id:, species:)
    observations_with_images = ParticipationObservationsMatview.where(participation_id: participation_id).where(scientific_name: species).has_images
    
    observations_with_images.each_with_index do |o, i|
      Rails.logger.info("---------------------------------") if i == 0
      Rails.logger.info("observations_with_images: scientific_name: #{o.scientific_name}") if i == 0
    end
    species.map! do |s|
      obs = observations_with_images.detect { |o| s == o["scientific_name"] }
      next unless obs.present?
      species_hash = Hash.new([])
      species_hash[:image] = obs["url"]
      species_hash[:scientific_name] = obs["scientific_name"]
      species_hash[:accepted_name] = obs["accepted_name"]
      species_hash[:common_name] = obs["common_name"]
      
      s = species_hash
    end
    return species.compact
  end

  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW participation_observations_matview')
  end

end
