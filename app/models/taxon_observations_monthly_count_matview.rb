class TaxonObservationsMonthlyCountMatview < ActiveRecord::Base
  self.table_name = 'taxon_observations_monthly_count_matview'
  self.primary_key = 'sysid'

  scope :filter_by_region, lambda { |region_id|
    where(region_id: region_id) if region_id.present?
  }
  scope :filter_by_month, lambda { |month_filter|
    where(month: month_filter.split(",").map(&:strip)) if month_filter.present?
  }
  scope :filter_by_year, lambda { |year_filter|
    where(year: year_filter.split(",").map(&:strip)) if year_filter.present?
  }
  scope :filter_by_taxonomy, lambda { |taxonomy_ids|
    where(taxonomy_id: taxonomy_ids) if taxonomy_ids.present?
  }

  def readonly?
    true
  end


  def self.get_species_count(region_id:, taxonomy_ids:, month_filter: nil, year_filter: nil)
    species_count = TaxonObservationsMonthlyCountMatview.where(region_id: region_id)
                                                        .filter_by_taxonomy(taxonomy_ids)
                                                        .filter_by_month(month_filter)
                                                        .filter_by_year(year_filter)
                                                        .sum(:observations_count)

    return species_count.as_json
  end


  def self.get_regions_by_species(search_text:, contest_id: nil, month_filter: nil, year_filter: nil)
    taxonomy_ids = []
    taxonomy_ids = RegionsObservationsMatview.get_taxonomy_ids(search_text: search_text)

    region_ids = []
    region_ids = TaxonObservationsMonthlyCountMatview.where(taxonomy_id: taxonomy_ids)
                                                     .filter_by_month(month_filter)
                                                     .filter_by_year(year_filter)
                                                     .distinct
                                                     .pluck(:region_id)
                                                     .compact
    base_region_ids = []
    base_region_ids = Region.where(id: region_ids)
                            .where(base_region_id: nil)
                            .pluck(:id)
    base_region_ids += Region.where(id: region_ids)
                             .where.not(base_region_id: nil)
                             .pluck(:base_region_id)
    regions_in_contests = []
    contest_query = ''
    contest_query = "contests.id = #{contest_id}" if contest_id.present?
    Contest.where(contest_query).in_progress.each do |c|
      regions_in_contests += c.regions.where(id: base_region_ids.compact.uniq).pluck(:id)
    end

    regions = Region.where(id: regions_in_contests.compact.uniq)
                    .where(base_region_id: nil)
                    .where(status: 'online')
  end


  def self.get_total_sightings_for_region(region_id:, taxonomy_ids: nil, month_filter: nil, year_filter: nil)
    locality = Region.find_by_id(region_id).get_neighboring_region(region_type: 'locality')
    greater_region = Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
    locality_species_count = greater_region_species_count = 0

    species_count = TaxonObservationsMonthlyCountMatview.get_species_count(region_id: region_id,
                                                                           taxonomy_ids: taxonomy_ids,
                                                                           month_filter: month_filter,
                                                                           year_filter: year_filter)
    if greater_region.present?
      locality_species_count = TaxonObservationsMonthlyCountMatview.get_species_count(region_id: locality.id,
                                                                                      taxonomy_ids: taxonomy_ids,
                                                                                      month_filter: month_filter,
                                                                                      year_filter: year_filter)
    end
    if greater_region.present?
      greater_region_species_count = TaxonObservationsMonthlyCountMatview.get_species_count(region_id: greater_region.id,
                                                                                            taxonomy_ids: taxonomy_ids,
                                                                                            month_filter: month_filter,
                                                                                            year_filter: year_filter)
    end

    species_count = species_count + locality_species_count + greater_region_species_count

    return species_count
  end


  def self.get_years
    years = TaxonObservationsMonthlyCountMatview.order("year desc").distinct.pluck(:year) || []
    return years
  end


  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY taxon_observations_monthly_count_matview')
  end
end
