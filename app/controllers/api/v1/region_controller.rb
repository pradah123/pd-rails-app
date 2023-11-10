require './services/region'
require './services/participation'

require './lib/common/utils'

module Api::V1
  class RegionController < ApiController
    # Create region API
    def create
      region = params[:region].permit!
      contest_ids = params[:contest] || []

      region['contest_ids'] = contest_ids
      region['api_hash'] = params[:api_hash]
      # api_hash is required to pass through external API calls only.
      # If API is called from GUI then, api_hash needed to be fetched from db constant
      if params[:gui_call].present?
        region['api_hash'] = Constant.find_by_name('api_hash').text_value if params[:gui_call] == 'true'
        params.delete(:gui_call)
      end
      region.delete(:polygon_side_length) if region[:polygon_side_length].blank? # It is expected to be float so for blank value it gives error

      create_params = region.to_unsafe_h.symbolize_keys
      Service::Region::Create.call(create_params) do |result|
        result.success do |message|
          render_success message
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    # Update region API
    def update
      region = params[:region].permit!
      contest_ids = params[:contest]
      region['contest_ids'] = params[:contest] if params.key?(:contest) && params[:contest]
      region['api_hash'] = params[:api_hash]
      # api_hash is required to pass through external API calls only.
      # If API is called from GUI then, api_hash needed to be fetched from db constant
      if params[:gui_call].present?
        region['api_hash'] = Constant.find_by_name('api_hash').text_value if params[:gui_call] == 'true'
        params.delete(:gui_call)
      end

      # For direct API access (e.g. through swagger or GOE), we don't get region['id'], hence needs to assign
      region['id'] = params[:id] || '' unless region['id']
      region.delete(:polygon_side_length) if region[:polygon_side_length].blank? # It is expected to be float so for blank value it gives error
      update_params = region.to_unsafe_h.symbolize_keys
      Service::Region::Update.call(update_params) do |result|
        result.success do |message|
          render_success message
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def search
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Region::Fetch.call(search_params) do |result|
        result.success do |regions|
          regions_json = []
          regions.each do |region|
            region_hash = RegionSerializer.new(region).serializable_hash[:data][:attributes]
            regions_json.push(region_hash)
          end
          render json: regions_json
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def show
      show_params = params.to_unsafe_h.symbolize_keys
      Service::Region::Show.call(show_params) do |result|
        result.success do |region|
          region_hash = RegionSerializer.new(region).serializable_hash[:data][:attributes]
          region_scores = region.get_region_scores
          region_hash.merge!(region_scores)
          contest_ids = region.contests.in_progress_or_upcoming.pluck(:id)
          contest_ids = contest_ids.map(&:to_s)
          region_hash[:contest] = contest_ids
          if params[:bioscore_pctile_contest_id]
            search_params = {}
            search_params[:contest_id] = params[:bioscore_pctile_contest_id]
            search_params[:offset] = 0
            search_params[:limit] = 9223372036854775807 #postgresql bigint last number
            search_params[:ignore_display_and_subscription_filter] = "true"
            # Get bioscore_percentile for given bioscore_pctile_contest_id
            Service::Participation::Fetch.call(search_params.symbolize_keys) do |regions|
              regions.success do |region|
                region.each do |r|
                  if r[:id] == params[:region_id].to_i
                    region_hash[:bioscore_percentile] = r[:bioscore_percentile]
                    region_hash[:species_diversity_percentile] = r[:species_diversity_percentile]
                    region_hash[:monitoring_percentile] = r[:monitoring_percentile]
                    region_hash[:community_percentile] = r[:community_percentile]
                    region_hash[:biovalue_percentile] = r[:biovalue_percentile]
                  end
                end
              end
              regions.failure do |message|
                raise ApiFail.new(message)
              end
            end
          end
          render json: region_hash
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def destroy
      delete_params = params.to_unsafe_h.symbolize_keys
      Service::Region::Delete.call(delete_params) do |result|
        result.success do |message|
          render_success message
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def search_by_species
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Region::SearchBySpecies.call(search_params) do |result|
        result.success do |searched_regions|
          render json: searched_regions
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def sightings_count
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Region::Sightings.call(search_params) do |result|
        result.success do |sightings_count|
          render json: sightings_count
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def species_image
      r = Region.find_by_id params[:region_id]
      raise ApiFail.new("Invalid region_id provided.") if r.blank?
      raise ApiFail.new("Must provide search_text.") unless params[:search_text]

      search_text = params[:search_text]
      raise ApiFail.new("Invalid search_text provided.") if search_text.blank?
      species_image = RegionsObservationsMatview.get_species_image(region_id: r.id,
                                                                   search_text: search_text)
      render json: species_image
    end

    def polygons_old
      data = {}

      DataSource.all.each do |ds|
        polygons = []
        Contest.in_progress.each do |c|
          c.participations.in_competition.each do |p|
            polygons.push JSON.parse(p.region.raw_polygon_json) if p.data_sources.include?(ds)
          end
        end    
        data[ds.name] = polygons
      end

      render json: data
    end

    def polygons
      data = {}

      regions = []
      Region.all.each do |r|
        json = { name: r.name }
        json[:data_sources] = r.participations.map { |p| p.data_sources }.flatten.uniq.map { |ds| ds.name }
        begin
          json[:polygons] = JSON.parse r.raw_polygon_json unless r.raw_polygon_json.nil?
        rescue
        end  
        regions.push json
      end
      data[:regions] = regions

      render json: data
    end  

    def data
      r = Region.find_by_id params[:region_id]
      c = Contest.find_by_id params[:contest_id]

      error_message = nil
      error_message = { status: 'error', message: "no region found with that id" } if r.nil?
      error_message = { status: 'error', message: "no contest found with that id" } if c.nil?
      unless error_message.nil?
        render json: error_message
        return
      end  

      p = r.participations.find_by_contest_id c.id
      if p.nil?
        render json: { status: 'error', message: "region not a contestant in this contest" }
        return
      end  
          
      data = { 
        title: r.name,
        observations: p.observations_count,
        species: p.species_count,
        identifications: p.identifications_count,
        people: p.people_count
      }

      render json: data
    end

    # This function returns polygon(square) of side length 1 km for given coordinates.
    # Used for API api/v1/region/polygon/from_coordinates
    # Required parameters are lat and lng
    # Optional parameters are polygon_side_length (if not passed considered as 1 km),
    #                         polygon_format (valid value is wkt, for anything else it will return
    #                                         polygon in geojson format)
    def generate_polygon
      lat = params[:lat]
      lng = params[:lng]
      polygon_side_length = params[:polygon_side_length] || 1
      polygon_format = params[:polygon_format]

      if !lat || !lng
        raise ApiFail.new("Must provide 'lat' and 'lng'")
      end
      polygon_radius = Utils.get_polygon_radius(polygon_side_length.to_f)
      polygon = Utils.get_polygon_from_lat_lng(lat, lng, polygon_radius)
      polygon = Region.get_polygon_from_raw_polygon_json(polygon.to_json) if polygon_format.present? && polygon_format == 'wkt'

      render json: { raw_polygon_json: polygon }
    end
  end
end 
