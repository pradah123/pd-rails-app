require_relative '../common/utils.rb'
require_relative './schema/observation.rb'
require_relative './naturespot/transformer.rb'

module Types
  include Dry.Types()
end

module Source
  class NatureSpot
    extend Dry::Initializer

    OBS_URL = 'https://www.spotteron.com/api/v2/spots?filter[topic_id]=32'.freeze
    #https://www.spotteron.com/api/v2/spots?filter[topic_id]=32&filter[category][]=4370&filter[category][]=4371&limit=10&page=1&order[]=id+desc
    SPECIES_DETAIL_URL = 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json'.freeze

    param :total, default: proc { nil }, reader: :private

    option :category_ids, optional: true, reader: :private, type: Types::Strict::Array
    option :created_at__gt, reader: :private, type: Types::Strict::String
    option :created_at__lt, reader: :private, type: Types::Strict::String
    option :longitude__lt, reader: :private, type: Types::Coercible::Float
    option :longitude__gt, reader: :private, type: Types::Coercible::Float
    option :latitude__lt, reader: :private, type: Types::Coercible::Float
    option :latitude__gt, reader: :private, type: Types::Coercible::Float

    option :limit, default: proc { 100 }, reader: :private, type: Types::Strict::Integer
    option :page, default: proc { 1 }, reader: :private, type: Types::Strict::Integer
    
    CATEGORY_IDS = [4370, 4371, 4372] ## We need to fetch only Animals, Plants and Fungi data

    def get_params()
      params = Source::NatureSpot.dry_initializer.attributes(self)
      if !params[:category_ids].present? 
        params[:"filter[category]"] = CATEGORY_IDS
      else
        params[:"filter[category]"] = params[:category_ids]
      end
      params.delete(:category_ids)
      params.delete(:total)
      params = restructure_params(params) 
      
      return params
    end

    def restructure_params(params)
      params[:"filter[created_at__gt]"] = params[:created_at__gt]
      params[:"filter[created_at__lt]"] = params[:created_at__lt]
      params[:"filter[longitude__lt]"] = params[:longitude__lt]
      params[:"filter[longitude__gt]"] = params[:longitude__gt]
      params[:"filter[latitude__lt]"] = params[:latitude__lt]
      params[:"filter[latitude__gt]"] = params[:latitude__gt]
      
      params.delete(:created_at__gt) 
      params.delete(:created_at__lt) 
      params.delete(:longitude__lt) 
      params.delete(:longitude__gt) 
      params.delete(:latitude__lt) 
      params.delete(:latitude__gt) 
      return params
    end

    def increment_page()
      @page += 1
    end

    def done()
        return  @total.present? && 
                (@page * @limit > @total)
    end

  
    def populate_scientific_name(transformed_obs)
      species_id = transformed_obs[:species_id]
      url = "#{SPECIES_DETAIL_URL}&ids=#{species_id}"
      
      response = HTTParty.get(
        url
      )

      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        scientific_name = result[:entities][:"#{species_id}"][:labels][:en][:value]
        return scientific_name
      else
        Delayed::Worker.logger.info "Source::GBIF.populate_scientific_name: #{response}"
      end

    end

    def get_observations()
      biosmart_obs = []
      response = HTTParty.get(
        OBS_URL,
        query: get_params(),
      )

      Delayed::Worker.logger.info "Source::NatureSpot.api_url: #{response.request.last_uri.to_s}"

      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        t = Source::NatureSpot::Transformer.new()
        @total = result[:meta][:total]

        result[:data].each do |obs|
          transformed_obs = t.call(obs)
          validation_result = Source::Schema::ObservationSchema.call(transformed_obs)
          if validation_result.failure?
            Delayed::Worker.logger.info "Source::NatureSpot.get_observations: #{obs}"
            Delayed::Worker.logger.error 'Source::NatureSpot.get_observations: ' + 
              "#{validation_result.errors.to_h.merge(unique_id: transformed_obs[:unique_id])}"
            next
          end
          if transformed_obs[:species_id].present? && transformed_obs[:species_id] != 'unknown'
            scientific_name = populate_scientific_name(transformed_obs)
            transformed_obs[:scientific_name] = transformed_obs[:accepted_name] = scientific_name
          else
            transformed_obs[:scientific_name] = transformed_obs[:accepted_name] = ''
          end
          transformed_obs.delete(:species_id)
          
          biosmart_obs.append(transformed_obs)
        end
      else
        @total = 0
        Delayed::Worker.logger.info "Source::GBIF.get_observations: #{response}"
      end
      Delayed::Worker.logger.info "Source::NatureSpot.get_observations biosmart_obs count: #{biosmart_obs.length}"

      return biosmart_obs
    end
  end
end
