class ParticipationSpeciesMatview < ActiveRecord::Base
  self.table_name = 'participation_species_matview'

  scope :has_scientific_name, -> { where.not scientific_name: @@filtered_scientific_names }
  scope :has_accepted_name, -> { where.not accepted_name: @@filtered_scientific_names }
  scope :ignore_species_code, -> { where('accepted_name != lower(accepted_name)') }
  scope :has_images, -> { where.not image: nil }

  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens', 'TBD']

  scope :filter_by_category, -> (category) {
    where(category) if category.present?
  }
  scope :filter_by_offset_limit, -> (n_start, n_end) {
    offset(n_start).limit(n_end) if n_start.present? && n_end.present?
  }

  def readonly?
    true
  end

  def self.get_top_species_with_images(participation_id:, offset: nil, limit: nil, category: nil)
    top_species = ::ParticipationSpeciesMatview.where(participation_id: participation_id)
                                               .filter_by_category(category)
                                               .has_scientific_name
                                               .has_images
                                               .select(:scientific_name, :common_name, :species_count, :image)
                                               .filter_by_offset_limit(offset, limit)
                                               .order('species_count' => 'desc')
    return top_species.as_json
  end

  def self.get_top_species(participation_id:, offset: nil, limit: nil, category: nil)
    top_species = ::ParticipationSpeciesMatview.where(participation_id: participation_id)
                                               .filter_by_category(category)
                                               .has_scientific_name
                                               .select(:scientific_name, :common_name, :species_count)
                                               .filter_by_offset_limit(offset, limit)
                                               .order('species_count' => 'desc')
    return top_species.as_json
  end

  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY participation_species_matview')
  end

end
