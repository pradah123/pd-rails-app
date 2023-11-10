class SpeciesMatview < ActiveRecord::Base
  self.table_name = 'species_matview'
  self.primary_key = 'sysid'

  scope :has_species_name, -> { where "lower(species_name) NOT IN (#{@@filtered_names}) AND species_name is not null" }
  scope :filter_by_species_name, lambda { |search_text|
    where("lower(species_name) like ?", "%#{search_text.downcase}%") if search_text.present?
  }
  @@filtered_names = "'arachnids', 'birds', 'other arthropods', 'other insects',
                     'other invertebrates', 'crustaceans', 'mammals',
                     'amphibians', 'reptiles', 'insects - butterflies and moths',
                     'fungi and friends', 'plants that do not flower', 'plants that flower',
                     'fish', 'insects - beetles', 'insects - ants, bees and wasps',
                     'insects - flies', 'insects - flies'"

  def readonly?
    true
  end

  def self.get_species(search_text: nil)
    species = []
    species = SpeciesMatview.has_species_name
                            .filter_by_species_name(search_text)
                            .order("species_name asc")
                            .pluck(:species_name)
                            .compact
                            .uniq { |s| s.upcase }
    return species
  end

  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY species_matview')
  end
end
