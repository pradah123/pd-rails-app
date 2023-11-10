require_relative '../../lib/common/utils.rb'

class RegionsObservationsMatview < ActiveRecord::Base
  self.table_name = 'regions_observations_matview'
  self.primary_key = 'sysid'
  scope :recent, -> { order observed_at: :desc }

  scope :has_scientific_name, -> { where.not scientific_name: @@filtered_scientific_names }
  scope :has_accepted_name, -> { where.not accepted_name: @@filtered_scientific_names }
  scope :from_observation_org, -> { joins(:data_source).where(data_sources: { name: 'observation.org' }) }
  scope :ignore_species_code, -> { where('accepted_name != lower(accepted_name)') }
  scope :has_creator_id, -> { where.not creator_id: nil }
  scope :without_creator_name, -> { where creator_name: nil }
  scope :has_images, -> { where('observation_images_count > 0') }
  scope :filter_by_region, lambda { |region_id|
    where(region_id: region_id) if region_id.present?
  }
  scope :filter_by_scientific_or_common_name, lambda { |search_text|
    where("scientific_name = ? or common_name = ?", search_text, search_text) if search_text.present?
  }
  scope :filter_by_date_range, lambda { |start_dt, end_dt|
    where("observed_at BETWEEN ? and ?", start_dt, end_dt) if start_dt.present? && end_dt.present?
  }
  scope :filter_by_taxonomy, lambda { |taxonomy_ids|
    where(taxonomy_id: taxonomy_ids) if taxonomy_ids.present?
  }
  scope :ignore_reserved_sightings, -> { where license_code: @@license_codes }


  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens']
  @@license_codes = [nil, 'cc-0', 'cc-by', 'cc-by-nc', 'cc-by-sa', 'cc-by-nd', 'cc-by-nc-sa', 'cc-by-nc-nd']

  has_many :observation_images

  def readonly?
    true
  end

  def self.get_observations_for_region(region_id:, start_dt: nil, end_dt: nil)
    obs = RegionsObservationsMatview.where(region_id: region_id)
    if start_dt.present? && end_dt.present?
      return obs.where("observed_at BETWEEN ? and ?", start_dt, end_dt)
    else
      return obs
    end
  end

  def self.get_taxonomy_ids(region_id: nil, search_text: nil)
    taxonomy_ids = []
    taxonomy_ids = RegionsObservationsMatview.filter_by_region(region_id)
                                             .filter_by_scientific_or_common_name(search_text)
                                             .group(:taxonomy_id)
                                             .pluck(:taxonomy_id)
                                             .compact
    return taxonomy_ids
  end

  def self.get_species_count(region_id:, taxonomy_ids:, start_dt: nil, end_dt: nil)
    start_dt = Utils.get_day_start_time(date_s: start_dt) if start_dt.present?
    end_dt   = Utils.get_day_end_time(date_s: end_dt) if end_dt.present?
    species_count = RegionsObservationsMatview.where(region_id: region_id)
                                              .filter_by_taxonomy(taxonomy_ids)
                                              .filter_by_date_range(start_dt, end_dt)
                                              .count(:id)

    return species_count.as_json
  end


  def self.get_regions_by_species(search_text:, contest_id: nil, start_dt: nil, end_dt: nil)
    taxonomy_ids = []
    taxonomy_ids = RegionsObservationsMatview.get_taxonomy_ids(search_text: search_text)

    start_dt = Utils.get_day_start_time(date_s: start_dt) if start_dt.present?
    end_dt   = Utils.get_day_end_time(date_s: end_dt) if end_dt.present?
    region_ids = []
    region_ids = RegionsObservationsMatview.where(taxonomy_id: taxonomy_ids)
                                           .filter_by_date_range(start_dt, end_dt)
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


  def self.get_total_sightings_for_region(region_id:, taxonomy_ids: nil, start_dt: nil, end_dt: nil)
    locality = Region.find_by_id(region_id).get_neighboring_region(region_type: 'locality')
    greater_region = Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
    locality_species_count = greater_region_species_count = 0

    species_count = RegionsObservationsMatview.get_species_count(region_id: region_id,
                                                                 taxonomy_ids: taxonomy_ids,
                                                                 start_dt: start_dt,
                                                                 end_dt: end_dt)
    if greater_region.present?
      locality_species_count = RegionsObservationsMatview.get_species_count(region_id: locality.id,
                                                                            taxonomy_ids: taxonomy_ids,
                                                                            start_dt: start_dt,
                                                                            end_dt: end_dt)
    end
    if greater_region.present?
      greater_region_species_count = RegionsObservationsMatview.get_species_count(region_id: greater_region.id,
                                                                                  taxonomy_ids: taxonomy_ids,
                                                                                  start_dt: start_dt,
                                                                                  end_dt: end_dt)
    end

    species_count = species_count + locality_species_count + greater_region_species_count

    return species_count
  end

  def self.get_species_image(region_id:, search_text:)
    taxonomy_ids = []
    taxonomy_ids = RegionsObservationsMatview.get_taxonomy_ids(search_text: search_text)

    obs_id = RegionsObservationsMatview.where(region_id: region_id)
                                       .where(taxonomy_id: taxonomy_ids)
                                       .has_images
                                       .ignore_reserved_sightings
                                       .order("observed_at desc")
                                       .limit(1)
                                       .pluck(:id)
    species_image = ObservationImage.where(observation_id: obs_id).pluck(:url).first
    return species_image if species_image.present?

    greater_region = Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
    region_id = greater_region.id if greater_region.present?
    obs_id = RegionsObservationsMatview.where(region_id: region_id)
                                       .where(taxonomy_id: taxonomy_ids)
                                       .has_images
                                       .ignore_reserved_sightings
                                       .order("observed_at desc")
                                       .limit(1)
                                       .pluck(:id)
    species_image = ObservationImage.where(observation_id: obs_id).pluck(:url).first
    return species_image
  end


  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY regions_observations_matview')
  end
end
