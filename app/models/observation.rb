require_relative '../../lib/common/utils.rb'
class Observation < ApplicationRecord
  scope :recent, -> { order observed_at: :desc }
  scope :has_images, -> { where 'observation_images_count > ?', 0 }
  scope :has_scientific_name, -> { where.not scientific_name: @@filtered_scientific_names }
  scope :has_accepted_name, -> { where.not accepted_name: @@filtered_scientific_names }
  scope :from_observation_org, -> { joins(:data_source).where(data_sources: { name: 'observation.org' }) }
  scope :ignore_species_code, -> { where('accepted_name != lower(accepted_name)') }
  scope :has_creator_id, -> { where.not creator_id: nil }
  scope :without_creator_name, -> { where creator_name: nil }
  scope :search, -> (q) { where 'search_text LIKE ?', "%#{q.downcase}%" }
  scope :sort_by_data_source, -> (priority) {
    ret = "CASE"
    priority.each_with_index do |p, i|
      ret << " WHEN observations.data_source_id = '#{p}' THEN #{i}"
    end
    ret << " ELSE #{priority.count} END"
    order(Arel.sql(ret))
  }
  scope :ignore_reserved_sightings, -> { where license_code: @@license_codes }

  #
  # an observation may belong to multiple regions, participations, or contests
  #

  has_and_belongs_to_many :regions
  has_and_belongs_to_many :participations
  has_and_belongs_to_many :contests
  belongs_to :data_source
  belongs_to :taxonomy
  has_many :observation_images

  # after_save :update_search_text, :update_address, :add_to_regions_and_contests
  after_save :update_search_text

  validates :unique_id, presence: true
  validates :lat, presence: true
  validates :lng, presence: true
  validates :observed_at, presence: true

  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens']
  @@license_codes = [nil, 'cc-0', 'cc-by', 'cc-by-nc', 'cc-by-sa', 'cc-by-nd', 'cc-by-nc-sa', 'cc-by-nc-nd']
  @@nobservations_per_page = 18

  def update_search_text
    update_column :search_text, "#{scientific_name} #{common_name} #{accepted_name} #{creator_name}".downcase
  end

  def update_address
    #
    # get the text location for this lat lng, via the google geocode api.
    # currently not used, was intended to show this data in the observations cards.
    #

    google_api_key = "AIzaSyBFT4VgTIfuHfrL1YYAdMIUEusxzx9jxAQ"
    url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{self.lat},#{self.lng}&key=#{google_api_key}"
    begin
      response = HTTParty.get url
      response_json = JSON.parse response.body
      Rails.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      Rails.logger.info response_json
      Rails.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      address = ""#response_json['results']
      update_column :address, address
    rescue => e
      Rails.logger.error "google gecode api failed for lat,lng = #{lat},#{lng}"
    end
  end

  ### Method for adding an observation to matching regions, participations and contests
  def add_to_regions_and_contests(geokit_point, region_id, data_source_id=nil, participant_id=nil)
    fetch_for_regions = []
    r = Region.find_by_id(region_id)
    # When observations are fetched for neighboring region(greater region),
    # those shall be linked to the base region and neighboring regions too
    if r.base_region_id.present?
      fetch_for_regions.push(Region.find_by_id(r.base_region_id))
      neighboring_regions = Region.find_by_id(r.base_region_id).neighboring_regions
      fetch_for_regions.concat(neighboring_regions)
    else
      # When observations are fetched for base region, those shall be linked to the base region only and
      # not to neighboring regions
      fetch_for_regions.push(r)
    end
    fetch_for_regions.each do |region|
      region.get_geokit_polygons.each do |polygon|

        if polygon.contains?(geokit_point)
          ## Add observation to region only if it's not already added
          obs = find_observation(region_id: region.id,
                                 observation_id: self.id,
                                 data_source_id: data_source_id)
          if obs.blank?
            begin
              insert_sql = get_observations_regions_insert_statement(region_id: region.id,
                                  observation_id: self.id, data_source_id: data_source_id)
              ActiveRecord::Base.connection.execute insert_sql
            rescue => error
              Delayed::Worker.logger.info("ERROR for region_id: #{region.id}, observation_id: #{id}, data_source_id: #{data_source_id} #{error.message}")
            end
          end

          participations = (participant_id.present? ? region.participations.where(id: participant_id) : region.participations)
          participations.each do |participation|
            if can_participate_in(participation)
              #
              # this observation is in this contest in time and space
              # add references for this observation to contest, participation only if
              # doesn't exist already
              if !participation.contest.observations.exists?(self.id) &&
                 !region.base_region_id.present? # Need to make sure we don't store neighboring region observation in contest
                participation.contest.observations << self
              end
              if !participation.observations.exists?(self.id)
                participation.observations << self
              end
            end
          end
          break
        end
      end
    end
  end

  #
  #  Method of updating observations to regions, participations, and contests,
  #  in the case where we need to be continously fetching data for all regions.
  #
  def update_to_regions_and_contests(region_id: , data_source_id: nil, participant_id: nil)
    geokit_point = Geokit::LatLng.new lat, lng
    data_source_id = data_source_id.present? ? data_source_id : data_source.id

    #
    # remove any existing relations with regions, participations
    # and contests only if observation exists in the system
    #

    ## Commenting following code as of now because currently if observation doesn't belong to any region
    ## anymore, it is getting deleted but it's not checking whether it belongs to any other
    ## region or not. Will fix in Trello 362
    # regions.each do |region|
    #   inside = false
    #   region.get_geokit_polygons.each do |polygon|
    #     if polygon.contains?(geokit_point)
    #       inside = true
    #       break
    #     end
    #   end
    #   if inside==false
    #     Delayed::Worker.logger.info("Deleting observation id: #{id} with unique id : #{unique_id}
    #       for region - #{region.name}, #{region.id}")
    #     region.observations.where(id: id).delete_all
    #   end
    # end

    ## Commenting following code as of now because currently if observation doesn't belong
    ## to any participation anymore, it is not getting deleted
    ## but it's getting deleted for gbif as we don't add gbif in participation
    ## Will fix in Trello 362
    # participations.each do |participation|
    #   unless can_participate_in(participation)
    #     Delayed::Worker.logger.info("Deleting observation id: #{id} with unique id : #{unique_id}
    #       for participation - #{participation.id}")
    #     participation.observations.where(id: id).delete_all
    #     participation.contest.observations.where(id: id).delete_all
    #   end
    # end

    ## Add observation to regions and contests
    self.add_to_regions_and_contests geokit_point, region_id, data_source_id, participant_id

  end

  def can_participate_in participation
    # from one of the requested data sources
    return false unless participation.data_sources.include?(data_source)

    # Check if competition is on going or not
    return false unless participation.is_active?

    # observed in the period of the contest
    return false unless observed_at>=participation.starts_at && observed_at<participation.ends_at

    # submitted in the allowed period
    return false unless created_at>=participation.starts_at && created_at<participation.last_submission_accepted_at

    true
  end

  ## This will return observations associated with observations_regions for given region_id, data source(gbif or no gbif),  and date range
  def self.get_observations_for_region(region_id: , start_dt: nil, end_dt: nil, include_gbif: false)
    obs = Observation.joins("JOIN OBSERVATIONS_REGIONS obsr ON obsr.observation_id = observations.id").
                            where(["obsr.region_id = ?", region_id])
    data_source_clause = (include_gbif == true ? "obsr.data_source_id = ?" : "obsr.data_source_id != ?")
    obs = obs.where([data_source_clause, DataSource.find_by_name('gbif').id])

    if start_dt.present? && end_dt.present?
      return obs.where("observed_at BETWEEN ? and ?", start_dt ,end_dt)
    else
      return obs
    end
  end


  # This will return an Observation associated with OBSERVATIONS_REGIONS for given region_id, observation_id and data source
  def find_observation(region_id: , observation_id: nil, data_source_id:)
    obs = Observation.joins(" JOIN OBSERVATIONS_REGIONS obsr ON obsr.observation_id = observations.id").
                            where(["obsr.observation_id = ?", observation_id]).
                            where(["obsr.region_id = ?", region_id]).
                            where(["obsr.data_source_id = ?", data_source_id])

    return obs
  end

  # This will return insert statement for OBSERVATIONS_REGIONS table
  def get_observations_regions_insert_statement(region_id: , observation_id: , data_source_id:)
    insert_sql = "INSERT INTO OBSERVATIONS_REGIONS(region_id, observation_id, data_source_id,
                                                  created_at, updated_at)
                  VALUES(#{region_id}, #{observation_id}, #{data_source_id},
                        '#{Time.now}', '#{Time.now}')"
    return insert_sql
  end


  # This will return observations fetched as per given filters
  def self.filter_observations(category:, q:, obj:, start_dt: nil, end_dt: nil)
    observations = nil
    if category.present?
      category_query = Utils.get_category_rank_name_and_value(category_name: category)
    end
    # For home page
    if obj.nil?
      if category.present? && q.present?
        observations = Observation.joins(:taxonomy).where("observed_at <= ?", Time.now).where(category_query).search(q)
      elsif category.present?
        observations = Observation.joins(:taxonomy).where("observed_at <= ?", Time.now).where(category_query)
      elsif q.present?
        observations = Observation.where("observed_at <= ?", Time.now).search(q)
      else
        observations = Observation.where("observed_at <= ?", Time.now)
      end
    else
      # For region page
      if obj.first.is_a? Region
        # observations = get_observations_for_region(region_id:    obj.first.id,
        #                                   start_dt:     start_dt,
        #                                   end_dt:       end_dt,
        #                                   include_gbif: true)
        if q.present?
          taxonomy_ids = RegionsObservationsMatview.get_taxonomy_ids(search_text: q)
        end
        observations = obs = obj.first.observations.where("observed_at <= ?", Time.now).distinct
        Rails.logger.info("observations count: #{observations.count}")
        if observations.present?
          if category.present? && q.present?
            observations = observations.where(taxonomy_id: taxonomy_ids).joins(:taxonomy).where(category_query)
          elsif category.present?
            observations = observations.joins(:taxonomy).where(category_query)
          elsif q.present?
            observations = observations.where(taxonomy_id: taxonomy_ids)
          end
        end
      else
        ends_at = obj.first.ends_at > Time.now ? Time.now : obj.first.ends_at
        if obj.first.is_a? Participation
          obs = obj.first.region.observations.where("observed_at BETWEEN ? and ?", obj.first.starts_at, ends_at).distinct
        else
          region_ids = obj.first.participations.map { |p|
            p.is_active? && !p.region.base_region_id.present? ? p.region.id : nil
          }.compact
          obs = Observation.joins(:observations_regions).where("observations_regions.region_id IN (?)", region_ids).where("observations.observed_at BETWEEN ? and ?", obj.first.starts_at, ends_at).distinct
        end
        # For contest or participation page
        if category.present? && q.present?
          observations = obs.joins(:taxonomy).where(category_query).search(q)
        elsif category.present?
          observations = obs.joins(:taxonomy).where(category_query)
        elsif q.present?
          observations = obs.search(q)
        else
          observations = obs
        end
      end
    end

    return observations
  end

  def self.get_search_results region_id, contest_id, q, nstart, nend, category = 'All Categories'
    #
    # returns observations in a region and/or contest which match
    # a keyword search for q and with limit as per given nstart to nend params
    #
    # one or both of region and contest may be nil
    #
    nstart = nstart || 0
    nend   = nend   || 18
    offset = nstart
    limit  = nend - nstart

    start_dt = end_dt = nil
    if region_id && contest_id
      obj = Participation.where contest_id: contest_id, region_id: region_id
    elsif region_id
      obj = Region.where id: region_id
      (start_dt, end_dt) = obj.first.get_date_range_for_report()
    elsif contest_id
      obj = Contest.where id: contest_id
    else
      obj = nil
    end

    q = q.blank? ? '' : q.strip
    category = '' if category == 'All Categories'
    observations = filter_observations(category: category, q: q, obj: obj, start_dt: start_dt, end_dt: end_dt)
    nobservations_all = observations.count
    nobservations_with_images = observations.has_images.has_scientific_name.count
    nobservations_excluded = nobservations_all - nobservations_with_images

    observations = observations.includes(:observation_images)
                               .has_images
                               .has_scientific_name
                               .ignore_reserved_sightings
                               .recent
                               .offset(offset)
                               .limit(limit)

    { observations: observations, nobservations: nobservations_all, nobservations_excluded: nobservations_excluded }
  end



  #
  #  code used to create observations in the old code
  #

  def self.store observations
    nupdates = 0
    nupdates_no_change = 0
    nupdates_failed = 0
    nfields_updated = 0
    ncreates = 0
    ncreates_failed = 0

    observations.each do |params|
      obs = Observation.find_by_unique_id params[:unique_id]
      image_urls = (params.delete :image_urls) || []

      if obs.nil?
        obs = Observation.new params
        if obs.save
          ncreates += 1
          image_urls.each do |url|
            ObservationImage.create! observation_id: obs.id, url: url
          end
        else
          ncreates_failed += 1
          Rails.logger.info "\n\n\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
          Rails.logger.info "Create failed on observation"
          Rails.logger.info obs.inspect
          Rails.logger.info params.inspect
          Rails.logger.info "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n\n"
        end

      else
        obs.attributes = params
        if obs.changed.empty?
          nupdates_no_change += 1
        else
          nupdates += 1
          nfields_updated += obs.changed.length
          if obs.save

            current_image_urls = obs.observation_images.pluck :url
            if current_image_urls-image_urls!=[]
              # if the images given are not the same as the ones present, delete the old
              # ones and remake them
              obs.observation_images.delete_all
              image_urls.each do |url|
                ObservationImage.create! observation_id: obs.id, url: url
              end
            end

          else
            nupdates_failed +=1
            Rails.logger.info "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            Rails.logger.info "Update failed on observation #{obs.id}"
            Rails.logger.info obs.inspect
            Rails.logger.info params.inspect
            Rails.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n\n"
          end
        end
      end

    end

  end





  #
  # caching of observations data per page, to speed up page loading
  # no longer used.
  #

  @@page_cache = {}
  @@page_cache_last_update = {}

  def self.add_observation_to_page_caches obs, contest, region, participation

=begin
    if top_page_cache.length==0
      @@top_page_cache =
    end
    if can_add_to_cache(obs)==false
      @@top_page_cache.prepend obs
      @@top_page_cache = @@top_page_cache.shift unless @@top_page_cache.count>@@nobservations_per_page
    end
=end
  end

  def self.get_observations obj=nil
    key = get_key obj
    now = Time.now
    if @@page_cache[key].blank? || (@@page_cache_last_update[key]>now+30.minutes)
      if obj.nil?
        @@page_cache[key] = Observation.all.has_images.recent.first @@nobservations_per_page
      else
        @@page_cache[key] = obj.observations.has_images.recent.first @@nobservations_per_page
      end
      @@page_cache_last_update[key] = now
    end
    @@page_cache[key]
  end

  def self.get_key obj
    obj.nil? ? 'top' : "#{ obj.class.name[0] }#{ obj.id }"
  end

  def self.can_add_to_cache obs
    return false if @@filtered_scientific_names.include?(observation.scientific_name)
    return false if obs.observation_images_count==0
    true
  end

  def observed_at_utc
    return "#{ observed_at.strftime '%Y-%m-%d %H:%M' } UTC"
  end

  def created_at_utc
    return "#{ created_at.strftime '%Y-%m-%d %H:%M' } UTC"
  end

  def updated_at_utc
    return "#{ updated_at.strftime '%Y-%m-%d %H:%M' } UTC"
  end

  # This function checks if taxonomy exists for given scientific_name or not
  # a. If doesn't exist then
  #    a.extracts from gbif using api https://api.gbif.org/v1/species?name=<scientific_name>
  #    b. If doesn't find any record then tries to extract using api https://api.gbif.org/v1/species/match?verbose=true&strict=false&name=<scientific_name> if doesn't find any record by first url.
  #    c. Stores the taxonomy details
  # b. If the taxonomy has synonym key then checks whether synonym taxonomy already exists or not.
  #    If doesn't exist then extracts synonym taxonomy using gbif api https://api.gbif.org/v1/species/<synonym key>
  # c. Update all observations taxonomy_id with either synonym taxonomy's id if exits or taxonomy's id
  def self.update_taxonomy(scientific_name:)
    return unless scientific_name.present?

    # Check if taxonomy already exists for given scientific_name
    # If doesn't exist then fetch the taxonomy from gbif and store it in taxonomies
    taxonomy = Taxonomy.where(scientific_name: scientific_name).or(Taxonomy.where(canonical_name: scientific_name)).first
    if !taxonomy.present? && scientific_name != 'TBD'
      record = Taxonomy.get_taxonomy_from_gbif(scientific_name: scientific_name)
      if record.present?
        transformed_record = Taxonomy.transform_record(record: record)
        if transformed_record.present?
          taxonomy = Taxonomy.find_by_taxon_id(transformed_record['taxonID'])
          taxonomy = Taxonomy.store_taxonomy(params: transformed_record) unless taxonomy.present?
          Delayed::Worker.logger.info "Inserted taxonomy for scientific_name #{scientific_name} with id #{taxonomy&.id} and taxon_id #{taxonomy&.taxon_id}" if taxonomy.present?
        end
      end
    end
    # If taxonomy has synonym then check if synonym's taxonomy already exists
    # If doesn't exist then fetch the taxonomy from gbif and store it in taxonomies
    if taxonomy&.accepted_name_usage_id.present?
      synonym_taxonomy = Taxonomy.find_by_taxon_id(taxonomy.accepted_name_usage_id)
      unless synonym_taxonomy.present?
        synonym_record = Taxonomy.get_synonym_taxonomy_from_gbif(accepted_name_usage_id: taxonomy.accepted_name_usage_id)
        if synonym_record.present?
          transformed_synonym_record = Taxonomy.transform_record(record: synonym_record)
          if transformed_synonym_record.present?
            synonym_taxonomy = Taxonomy.find_by_taxon_id(transformed_synonym_record['taxonID'])
            synonym_taxonomy = Taxonomy.store_taxonomy(params: transformed_synonym_record) unless synonym_taxonomy.present?
            Delayed::Worker.logger.info "Inserted synonym taxonomy for scientific_name #{scientific_name} with id #{synonym_taxonomy&.id} and taxon_id #{synonym_taxonomy&.taxon_id}" if synonym_taxonomy.present?
          end
        end
      end
    end
    # Update observations taxonomy_id with stored synonym taxonomy's id or taxonomy's id
    taxonomy_id = synonym_taxonomy.present? ? synonym_taxonomy.id : taxonomy&.id
    taxonomy_updated = Observation.where(scientific_name: scientific_name).update_all(taxonomy_id: taxonomy_id) if taxonomy_id.present?
    Delayed::Worker.logger.info "Updated taxonomy for observations with taxonomy id: #{taxonomy_id}, #{taxonomy&.id}" if taxonomy_updated.present?
  end


  # Update taxonomies to observations
  # This will be used mainly for one shot update at the start for updating taxonomies for existing observations
  def self.update_observations_taxonomy(update_all: nil, from_date: nil)
    # If update_all has been passed then update the taxonomy for all the observatiobs using distinct scientific names
    # else only update those observations which don't have taxonomy linked with them
    if update_all.present?
      scientific_names = Observation.group(:scientific_name).order("count(id) desc").pluck(:scientific_name)
    else
      from_date ||= Date.today
      scientific_names = Observation.where("created_at > '#{from_date}'")
                                    .where(taxonomy_id: nil)
                                    .where
                                    .not(scientific_name: nil)
                                    .distinct
                                    .pluck(:scientific_name)
    end
    scientific_names.each do |scientific_name|
      TaxonomyUpdateJob.perform_later(scientific_name: scientific_name)
    end
  end

  def self.get_total_observations_count
    return TotalObservationsMetricsMatview.get_total_observations_count()
  end

  def self.get_total_species_count
    return TotalObservationsMetricsMatview.get_total_species_count
  end

  def self.get_total_people_count
    return TotalObservationsMetricsMatview.get_total_people_count
  end

  def self.get_total_identifications_count
    return TotalObservationsMetricsMatview.get_total_identifications_count
  end


  def self.get_closest_sightings_to_location(lat, lng, nstart, nend)
    regions = Region.where(base_region_id: nil).where.not(raw_polygon_json: nil)
    final_regions = []
    regions.each do |r|
      polygon_geojson = r.get_polygon_json
      is_region_near_to_point = r.is_region_near_to_point(lat, lng)
      next unless is_region_near_to_point.present?
      (min_dist, max_dist) = Region.distance_from_point(lat, lng, polygon_geojson)
      final_regions.push([r.id, min_dist])
    end
    final_regions.sort! do |a, b|
      a[1] <=> b[1]
    end
    Rails.logger.info("Observation::get_closest_sightings_to_location => final_regions #{final_regions}")
    license_codes = "null, 'cc-0', 'cc-by', 'cc-by-nc', 'cc-by-sa', 'cc-by-nd', 'cc-by-nc-sa', 'cc-by-nc-nd'"

    results = []
    final_regions.each do |fr|
      region_id = fr[0]
      begin
        select_sql = "select final_observations.*, oi.url as images from (SELECT al.id, " \
                    "al.scientific_name as sname,al.common_name as cname, al.accepted_name, " \
                    "al.observed_at, al.created_at, al.updated_at, al.bioscore as gold_rewarded, " \
                    "al.taxonomy_id, al.unique_id, al.identifications_count, al.creator_id, al.address, " \
                    "al.civilization_name, al.civilization_color, al.data_source_id, " \
                    "al.civilization_profile_pic as civilization_profile_image, distance, " \
                    "al.lat, al.lng, al.creator_name as fullname, al.license_code " \
                    "FROM (SELECT  distinct o.*,( 6371 * acos( cos( radians(#{lat}) ) * " \
                    "cos( radians( lat ) ) * cos( radians( lng ) - radians(#{lng}) ) + " \
                    "sin( radians(#{lat}) ) * sin( radians( lat ) ) ) ) " \
                    "AS distance FROM observations o " \
                    "INNER JOIN observations_regions org " \
                    "ON org.observation_id = o.id " \
                    "WHERE org.region_id = #{region_id} AND " \
                    "o.license_code IN (#{license_codes}) AND " \
                    "o.taxonomy_id is not null AND " \
                    "o.data_source_id not in (select ds.id from data_sources ds where ds.name='qgame') AND " \
                    "o.observation_images_count > 0 ) al " \
                    "ORDER BY distance limit #{nend} offset(#{nstart})) as final_observations " \
                    "inner join observation_images oi on " \
                    "final_observations.id = oi.observation_id"
        Rails.logger.info("select_sql: #{select_sql}")
        results = ActiveRecord::Base.connection.execute select_sql
      rescue => e
        Delayed::Worker.logger.info("ERROR for getting closest sightings data #{e.message}")
      end
      break if results.to_json.length.positive?
    end
    return results
  end




  rails_admin do
    list do
      field :id
      field :creator_name
      field :unique_id
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
      field :created_at
    end
    edit do
      field :data_source
      field :creator_name
      field :unique_id
      field :common_name
      field :accepted_name
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
    end
    show do
      field :id
      field :creator_name
      field :unique_id
      field :common_name
      field :accepted_name
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
      field :created_at
    end
  end

end
