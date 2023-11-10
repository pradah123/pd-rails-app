class ParticipationObservationsView < ActiveRecord::Base
  self.table_name = 'participation_observations_view'
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
    # observations_with_images = ParticipationObservationsView.where(participation_id: participation_id).where(scientific_name: species).has_images.select('DISTINCT ON (scientific_name, common_name) scientific_name, accepted_name, common_name, url')
    final_species_hash = Hash.new([])
    species.map! do |s|
      # obs = observations_with_images.detect{ |o| s == o.scientific_name }
      obs = ParticipationObservationsView.where(participation_id: participation_id).where(scientific_name: s).has_images.select('DISTINCT ON (scientific_name, common_name) scientific_name, accepted_name, common_name, url').first
      next unless obs.present?
      species_hash = Hash.new([])
      species_hash[:image] = obs.url
      species_hash[:scientific_name] = obs.scientific_name
      species_hash[:accepted_name] = obs.accepted_name
      species_hash[:common_name] = obs.common_name
      
      final_species_hash[:scientific_name] = obs.scientific_name
      s = species_hash
    end
    return species.compact
  end


end
