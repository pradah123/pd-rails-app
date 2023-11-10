class GbifObservationsMatview < ActiveRecord::Base
  self.table_name = 'gbif_observations_matview'
  scope :recent, -> { order observed_at: :desc }

  scope :has_scientific_name, -> { where.not scientific_name: @@filtered_scientific_names }
  scope :has_accepted_name, -> { where.not accepted_name: @@filtered_scientific_names }
  scope :from_observation_org, -> { joins(:data_source).where(data_sources: { name: 'observation.org' }) }
  scope :ignore_species_code, -> { where('accepted_name != lower(accepted_name)') }
  scope :has_creator_id, -> { where.not creator_id: nil }
  scope :without_creator_name, -> { where creator_name: nil }

  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens']

  has_many :observation_images

  def readonly?
    true
  end

  def self.get_observations_for_region(region_id:, start_dt: nil, end_dt: nil)
    obs = GbifObservationsMatview.where(region_id: region_id)
    if start_dt.present? && end_dt.present?
      return obs.where("observed_at BETWEEN ? and ?", start_dt, end_dt)
    else
      return obs
    end
  end

  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW gbif_observations_matview')
  end
end
