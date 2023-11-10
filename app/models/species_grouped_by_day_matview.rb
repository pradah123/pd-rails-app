class SpeciesGroupedByDayMatview < ActiveRecord::Base
  self.table_name = 'species_grouped_by_day_matview'

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

  def self.get_top_species_with_images(region_id:, offset: nil, limit: nil, category: nil, start_dt: nil, end_dt: nil)
    top_species = ::SpeciesGroupedByDayMatview.where(region_id: region_id)
                                              .where("observed_at BETWEEN ? and ?", start_dt, end_dt)
                                              .group('scientific_name')
                                              .select("max(scientific_name) as scientific_name, sum(species_count) as species_count, max(common_name) as common_name, max(image) as image")
                                              .filter_by_category(category)
                                              .has_scientific_name
                                              .has_images
                                              .filter_by_offset_limit(offset, limit)
                                              .order('species_count desc, scientific_name')
    return top_species.as_json
  end

  def self.get_top_species(region_id:, offset: nil, limit: nil, category: nil, start_dt: nil, end_dt: nil)
    top_species = ::SpeciesGroupedByDayMatview.where(region_id: region_id)
                                              .where("observed_at BETWEEN ? and ?", start_dt, end_dt)
                                              .group('scientific_name')
                                              .select("max(scientific_name) as scientific_name, sum(species_count) as species_count, max(common_name) as common_name, max(image) as image")
                                              .filter_by_category(category)
                                              .has_scientific_name
                                              .filter_by_offset_limit(offset, limit)
                                              .order('species_count desc, scientific_name')
    return top_species.as_json
  end

  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY species_grouped_by_day_matview')
  end

end
