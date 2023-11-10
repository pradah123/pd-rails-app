require './services/observation'

module Api::V1
  class ObservationController < ApiController

    def search
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Observation::Fetch.call(search_params) do |result|
        result.success do |observations|
          if params[:get_counts_only] == 'true'
            render json: observations
          else
            serialized_observations = []
            observations.each do |obs|
              serialized_observations.push(ObservationSerializer.new(obs).serializable_hash[:data][:attributes])
            end
            render json: serialized_observations
          end
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def top_species
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Observation::FetchSpecies.call(search_params) do |result|
        result.success do |top_species|
          render json: { top_species: top_species }
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def top_people
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Observation::FetchPeople.call(search_params) do |result|
        result.success do |top_people|
          render json: { top_people: top_people }
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def undiscovered_species
      search_params = params.to_unsafe_h.symbolize_keys

      Service::Observation::FetchUndiscoveredSpecies.call(search_params) do |result|
        result.success do |undiscovered_species|
          render json: { undiscovered_species: undiscovered_species }
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def bulk_create
      fail_message = nil
      fail_message = { status: 'fail', message: 'no data_source_name given' } if params[:data_source_name].nil?
      fail_message = { status: 'fail', message: "array of observations is required" } if params[:observations].nil?
      fail_message = { status: 'fail', message: "observations is not an array" } unless params[:observations].is_a?(Array)

      params[:observations].each do |obs|
        begin
          JSON.parse obs 
        rescue JSON::ParserError => e  
          fail_message = { status: 'fail', message: "observation data is not json: #{obs}" }
          break
        end
      end   

      unless fail_message.nil?
        render json: fail_message
        return
      end    

      data_source = DataSource.find_by_name params[:data_source_name]
      if data_source.nil?
        render json: { status: 'error', message: "data_source_name must be one of: #{ DataSource.all.pluck(:name).join(',') }" } 
        return
      end
        
      ObservationsCreateJob.perform_later data_source, params[:observations]
      render_success
    end
      
    def get_more
      nstart = params[:nstart]&.to_i || 0
      nend   = params[:nend]&.to_i || 24
      
      result = Observation.get_search_results params[:region_id], params[:contest_id], '', nstart, nend
      observations = result[:observations]

      observations = observations.map { |obs| {
        scientific_name: obs.scientific_name, 
        common_name: obs.common_name,
        creator_name: (obs.creator_name.nil? ? '' : obs.creator_name),
        observed_at: "#{ obs.observed_at.strftime '%Y-%m-%d %H:%M' } UTC",
        image_urls: obs.observation_images.pluck(:url),
        lat: obs.lat,
        lng: obs.lng
      } }
      
      j = { 'observations': observations }
      render_success j
    end

    def get_map_observations(obj, limit = nil)
      j = {}
      offset = 0
      if obj.is_a? Region
        observations = obj.observations.where("observed_at <= ?", Time.now).distinct
        # observations = Observation.get_observations_for_region(region_id: obj.id, include_gbif: true)
      elsif obj.is_a? Participation
        ends_at = obj.ends_at > Time.now ? Time.now : obj.ends_at
        observations = obj.region.observations.where("observed_at BETWEEN ? and ?", obj.starts_at, ends_at).distinct
      else
        ends_at = obj.first.ends_at > Time.now ? Time.now : obj.first.ends_at
        region_ids = obj.first.participations.map { |p|
          p.is_active? && !p.region.base_region_id.present? ? p.region.id : nil
        }.compact
        observations = Observation.joins(:observations_regions).where("observations_regions.region_id IN (?)", region_ids).where("observations.observed_at BETWEEN ? and ?", obj.first.starts_at, ends_at).distinct
      end
      limit = 5000 unless limit.present?
      observations = observations.recent
                                 .ignore_reserved_sightings
                                 .offset(offset).limit(limit)

      j['observations'] = obj.nil? ? [] : observations.map { |o|
         { id:  o.id,
           lat: o.lat,
           lng: o.lng
         } }

      render_success j
    end

    def get_observation_details obj
      j = {}
      j['observation'] = ObservationSerializer.new(obj).serializable_hash[:data][:attributes]

      render_success j
    end

    def data
      get_observation_details Observation.find_by_id params[:id]
    end

    def region
      get_map_observations Region.find_by_id params[:id]
    end  

    def participation
      get_map_observations((Participation.find_by_id params[:id]), params[:limit])
    end  

    def contest
      get_map_observations Contest.find_by_id params[:id]
    end

    def contest_region
      raise ApiFail.new("No contest id given") if params[:contest_id].blank?
      raise ApiFail.new("No region id given") if params[:region_id].blank?

      r = Region.find_by_id params[:region_id]
      c = Contest.find_by_id params[:contest_id]
      raise ApiFail.new("Region does not exist") unless r.present?
      raise ApiFail.new("Contest does not exist") unless c.present?

      p = r.participations&.find_by_contest_id c.id if r.present? && c.present?

      raise ApiFail.new("Region is not a participant in this contest") unless p.present?
      get_map_observations(p, params[:limit])
    end

    def get_species
      species = []
      if params[:term].present?
        search_text = params[:term]
        species = SpeciesMatview.get_species(search_text: search_text)
      else
        species = SpeciesMatview.get_species()
      end
      render_success species.uniq.to_json
    end

    def get_total_counts
      total_counts = {}
      total_counts[:identifications_count] = Observation.get_total_identifications_count()
      total_counts[:observations_count] = Observation.get_total_observations_count()
      total_counts[:species_count] = Observation.get_total_species_count()
      total_counts[:people_count] = Observation.get_total_people_count()

      render_success total_counts
    end


    def get_closest_sightings
      lat    = params[:lat]
      lng    = params[:lng]
      nstart = params[:offset] || 0
      nend   = params[:limit] || 15
      raise ApiFail.new("No 'lat' given") unless lat.present?
      raise ApiFail.new("No 'lng' given") unless lng.present?

      results = Observation.get_closest_sightings_to_location(lat, lng, nstart, nend)
      hash = {}
      final_results = []
      results.each do |r|
        if hash.key?("#{r['id']}")
          url = r["images"]
          urls = final_results[hash["#{r['id']}"]]["images"]
          final_urls = [url, urls]
          final_results[hash["#{r['id']}"]]["images"] = final_urls.flatten
        else
          r['data_source'] = "biosmart-#{DataSource.find_by_id(r['data_source_id']).name}"
          r.delete('data_source_id')
          r['category_name'] = Taxonomy.find_by_id(r['taxonomy_id']).get_category_name || ''
          r.delete('taxonomy_id')
          r['images'] = [r['images']]

          r['captured_user_info'] = {
            id: nil,
            exp_level: nil,
            fullname: r["fullname"],
            user_profile_pic: nil
          }
          r['verifier_response'] = nil
          r['model'] = nil
          r['user_id'] = nil
          final_results.push(r)
          hash["#{r['id']}"] = final_results.length - 1
        end
      end
      render_success final_results
    end


    def get_observation_for_questa
      id = params[:id]
      raise ApiFail.new("No 'id' given") unless id.present?
      obs = Observation.where(id: id).includes(:observation_images).first

      images = obs.observation_images.pluck(:url)
      final_images = []
      images.each do |i|
        final_images.push(
          { original: i,
            main: nil,
            thumb: nil})
      end
      final_obs = {
        id: obs.id,
        species: {
          cname: obs.common_name,
          sname: obs.scientific_name,
          image_url: nil
        },
        gold_rewarded: obs.bioscore,
        civilization_color: obs.civilization_color,
        user: {
          id: nil,
          fullname: obs.creator_name,
          profile_image: [],
          exp_level: nil,
          civilization_color: obs.civilization_color,
          civilization_name: obs.civilization_name,
          civilization_profile_image: obs.civilization_profile_pic
        },
        images: final_images
      }

      render_success final_obs
    end
  end
end 
