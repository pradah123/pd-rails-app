require_relative '../../lib/source/inaturalist.rb'
require_relative '../../lib/source/ebird.rb'
require_relative '../../lib/source/qgame.rb'
require_relative '../../lib/source/observation_org.rb'
require_relative '../../lib/source/mushroom_observer.rb'
require_relative '../../lib/source/gbif.rb'
require_relative '../../lib/source/naturespot.rb'
require_relative '../../lib/source/citsci.rb'


class DataSource < ApplicationRecord
  has_and_belongs_to_many :participations
  has_many :observations
  has_many :api_request_logs
  has_many :params, dependent: :delete_all
  has_many :contests, through: :params

  #
  # this is where to control the query parameters format
  # for each data source
  #

  def get_query_parameters subregion, extra_params=nil
    return {} if subregion.nil?

    case name
    when 'inaturalist'
      params = {
        lat: subregion.lat,
        lng: subregion.lng,
        radius: subregion.radius_km.ceil,
        geo: true,
        order: "desc",
        order_by: "observed_on",
        per_page: 200,
        page: 1
      }
      params.merge!(extra_params) if extra_params.present?
      return params

    when 'ebird'
      {
        lat: subregion.lat,
        lng: subregion.lng,
        dist: subregion.radius_km.ceil,
        sort: "date"
      }

    when 'qgame'
      multipolygon_wkt = Region.get_multipolygon_from_raw_polygon_json subregion.raw_polygon_json
      params = {
        multipolygon: multipolygon_wkt, 
        offset: 0, 
        limit: 50
      }
      params.merge!(extra_params) if extra_params.present?
      params[:category_ids] = params[:category_ids].join(",") if params[:category_ids].present?
      return params
    when 'observation.org'
      if subregion.region.observation_dot_org_id.nil?
        {}
      else
        params = {
          location_id: (subregion.region.observation_dot_org_id), 
          offset: 0, 
          limit: 100
        }
        params.merge!(extra_params) if extra_params.present?
        params[:species_group] = params[:species_group].join(",") if params[:species_group].present?
        return params
      end
    when 'mushroom_observer'
      if subregion.region.raw_polygon_json.present?
        parsed_polygon = JSON.parse(subregion.raw_polygon_json)
        west, east, south, north = Utils.get_bounding_box(parsed_polygon)
        return {
          north: north,
          south: south,
          east: east,
          west: west
        }
      else
        raise ArgumentError.new("Polygon does not exists for region #{subregion.region.id}")
      end
    when 'gbif'
      if subregion.raw_polygon_json.present?
        polygon_wkt = Region.get_polygon_from_raw_polygon_json(subregion.raw_polygon_json)
        return {
          offset: 0,
          limit: 300,
          geometry: polygon_wkt
        }
      else
        raise ArgumentError.new("Polygon does not exists for region #{subregion.id}")
      end
    when 'naturespot'
      if subregion.region.raw_polygon_json.present?
        parsed_polygon = JSON.parse(subregion.raw_polygon_json)
        west, east, south, north = Utils.get_bounding_box(parsed_polygon)
        params = {
          longitude__lt: east,
          longitude__gt: west,
          latitude__lt: north,
          latitude__gt: south
        }
        params.merge!(extra_params) if extra_params.present?
        return params
      else
        raise ArgumentError.new("Polygon does not exists for region #{subregion.region.id}")
      end
    when 'citsci'
      if subregion.region.citsci_project_id.present?
        return {
          project_id: subregion.region.citsci_project_id
        }
      else
        return {}
      end
    else
      {}
    end     
  end


  def fetch_observations region, starts_at, ends_at, extra_params=nil, participant_id=nil
    subregions = Subregion.where(region_id: region.id, data_source_id: id)
    subregions.each do |sr|
      case name
      when 'inaturalist'
        fetch_inat sr, starts_at, ends_at, extra_params, region.id, participant_id
      when 'ebird'
        fetch_ebird sr, starts_at, ends_at, region.id, participant_id
      when 'qgame'
        fetch_qgame sr, starts_at, ends_at, extra_params, region.id, participant_id
      when 'observation.org'
        fetch_observations_dot_org sr, starts_at, ends_at, extra_params, region.id, participant_id
      when 'mushroom_observer'
        fetch_mushroom_observer sr, starts_at, ends_at, region.id, participant_id
      when 'gbif'
        fetch_gbif sr, starts_at, ends_at, region.id
      when 'naturespot'
        fetch_naturespot sr, starts_at, ends_at, extra_params, region.id, participant_id
      when 'citsci'
        fetch_citsci sr, starts_at, ends_at, region.id, participant_id
      else
        self.send "fetch_#{name}", region # PRW: if you have the explicit case statements, we don't need this
      end
    end
  end

  ## Get total count for gbif request
  def fetch_gbif_observations_count region, starts_at, ends_at
    subregions = Subregion.where(region_id: region.id, data_source_id: id)
    total_count = 0
    subregions.each do |sr|
      total_count = total_count + fetch_gbif(sr, starts_at, ends_at, region.id, true)
    end
    return total_count
  end


  def fetch_gbif subregion, starts_at, ends_at, region_id, fetch_count=false
    Delayed::Worker.logger.info "fetch_observations_gbif(#{subregion.id},#{starts_at}, #{ends_at}, #{region_id}, #{fetch_count})"

    begin
      params = get_query_parameters subregion
      params[:eventDate] = "#{starts_at.strftime('%Y-%m-%d')},#{ends_at.strftime('%Y-%m-%d')}"

      gbif = ::Source::GBIF.new(**params)
      loop do
        if fetch_count.present?
          count = gbif.get_observations(fetch_count: fetch_count) || 0
          return count
        end
        observations = gbif.get_observations() || []
        observations.each{ |o|
          if subregion.contains? o[:lat], o[:lng]
            ObservationsCreateJob.perform_later self, [o], region_id
          end
        }
        gbif.increment_page()
        break if gbif.done()
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_gbif: #{e.full_message}"
    end
  end


  def fetch_citsci subregion, starts_at, ends_at, region_id, participant_id
    Delayed::Worker.logger.info "fetch_citsci(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion
      params[:observed_at] = "#{starts_at.strftime('%Y-%m-%d')},#{ends_at.strftime('%Y-%m-%d')}"
      if params[:project_id].present?
        citsci = ::Source::CitSci.new(**params)
        loop do
          observations = citsci.get_observations() || []
          observations.each{ |o|
            if subregion.region.contains? o[:lat], o[:lng]
              ObservationsCreateJob.perform_later self, [o], region_id, participant_id
            end
          }
          break if citsci.done()
          citsci.increment_page()
        end
      else
        Delayed::Worker.logger.info "fetch_citsci: Skipping get_observations as citsci_project_id is missing for the region '#{subregion.region.name}'"
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_citsci: #{e.full_message}"
    end
  end


  def fetch_naturespot subregion, starts_at, ends_at, extra_params, region_id, participant_id
    Delayed::Worker.logger.info "fetch_naturespot(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion, extra_params
      params[:created_at__gt] = starts_at.strftime('%F')
      params[:created_at__lt] = ends_at.strftime('%F')

      naturespot = ::Source::NatureSpot.new(**params)
      loop do
        observations = naturespot.get_observations() || []
        observations.each{ |o|
          if subregion.region.contains? o[:lat], o[:lng]
            ObservationsCreateJob.perform_later self, [o], region_id, participant_id
          end
        }
        break if naturespot.done()
        naturespot.increment_page()
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_naturespot: #{e.full_message}"
    end
  end


  def fetch_mushroom_observer subregion, starts_at, ends_at, region_id, participant_id
    Delayed::Worker.logger.info "fetch_mushroom_observer(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion
      params[:date] = "#{starts_at.strftime('%Y%m%d')}-#{ends_at.strftime('%Y%m%d')}"
      mushroom_observer = ::Source::MushroomObserver.new(**params)
      loop do                
          observations = mushroom_observer.get_observations() || []
          observations.each{ |o|
            if subregion.contains? o[:lat], o[:lng]
              ObservationsCreateJob.perform_later self, [o], region_id, participant_id
            end
          }
          mushroom_observer.increment_page()
          break if mushroom_observer.done()
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_mushroom_observer: #{e.full_message}"
    end
  end

  def fetch_observations_dot_org subregion, starts_at, ends_at, extra_params, region_id, participant_id
    # fetch logic here
    Delayed::Worker.logger.info "fetch_observations_dot_org(#{subregion.id}, #{starts_at}, #{ends_at})"

# Peter: we need the begin-rescue around the api call inside the function, not 
# around the creation job. otherwise we can't get the correct error messages on the creation
# of observations

    begin
      params = get_query_parameters subregion, extra_params
      params[:date_after] = starts_at.strftime('%F')
      params[:date_before] = ends_at.strftime('%F')

      ob_org = ::Source::ObservationOrg.new(**params)
      loop do                
          observations = ob_org.get_observations() || []

          observations.each{ |o|
            if subregion.region.contains? o[:lat], o[:lng]
              ObservationsCreateJob.perform_later self, [o], region_id, participant_id
            end
          }
          break if ob_org.done()
          ob_org.increment_offset()
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_observations_dot_org: #{e.full_message}"
    end
  end 

  def fetch_inat subregion, starts_at, ends_at, extra_params, region_id, participant_id # PRW: we should change this to fetch_inaturalist to be consistent
    # fetch logic here
    Delayed::Worker.logger.info "fetch_inat(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion, extra_params
      params[:d1] = starts_at.strftime('%F')
      params[:d2] = ends_at.strftime('%F')

      inat = ::Source::Inaturalist.new(**params)
      loop do
        observations = inat.get_observations() || []

        observations.each{ |o|
          if subregion.region.contains? o[:lat], o[:lng]
            ObservationsCreateJob.perform_later self, [o], region_id, participant_id
          end
        }
        break if inat.done()
        inat.increment_page()
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_inat: #{e.full_message}"
    end
  end 

  def fetch_ebird subregion, starts_at, ends_at, region_id, participant_id
    # fetch logic here
    Delayed::Worker.logger.info "fetch_ebird(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion
      params[:back] = (Time.now - starts_at).to_i / (24 * 60 * 60)
      params[:back] = 30 if params[:back] > 30
      ebird = ::Source::Ebird.new(**params)
      observations = ebird.get_observations() || []

      observations.each { |o|
        if subregion.region.contains? o[:lat], o[:lng]
          ObservationsCreateJob.perform_later self, [o], region_id, participant_id
        end
      }
    rescue => e
      Delayed::Worker.logger.error "fetch_ebird: #{e.full_message}"
    end
  end

  def fetch_qgame subregion, starts_at, ends_at, extra_params, region_id, participant_id
    # fetch logic here
    Delayed::Worker.logger.info "fetch_qgame(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion, extra_params
      params[:start_dttm] = starts_at.strftime('%F')
      params[:end_dttm] = ends_at.strftime('%F')

      qgame = ::Source::QGame.new(**params)    
      loop do      
        break if qgame.done()
        observations = qgame.get_observations() || []

        observations.each { |o|
          if subregion.region.contains? o[:lat], o[:lng]
            ObservationsCreateJob.perform_later self, [o], region_id, participant_id
          end
        }
        qgame.increment_offset()
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_qgame: #{e.full_message}"
    end
  end 
  
  rails_admin do
    list do
      field :id
      field :name
      field :created_at              
    end
    edit do
      field :name
    end
    show do
      field :id
      field :name
      field :created_at
    end
  end 

end
