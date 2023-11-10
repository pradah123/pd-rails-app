require_relative '../common/utils.rb'
require_relative './schema/observation.rb'
require_relative './citsci/transformer.rb'

module Types
  include Dry.Types()
end

module Source
  class CitSci
    extend Dry::Initializer

    OBS_URL = 'https://api.citsci.org/projects/ID/observations?itemsPerPage=300'.freeze
    SPECIES_DETAIL_URL = 'https://api.citsci.org'.freeze

    param :total, default: proc { nil }, reader: :private

    option :project_id, optional: true, reader: :private, type: Types::Strict::String
    option :observed_at, reader: :private, type: Types::Strict::String
    option :page, default: proc { 1 }, reader: :private, type: Types::Strict::Integer
    
    def get_params()
      params = Source::CitSci.dry_initializer.attributes(self)

      params.delete(:project_id)
      params.delete(:total)
      params.delete(:observed_at)

      return params
    end


    def increment_page()
      @page += 1
    end

    def done()
        return  @total.present? && 
                (@page * 300 > @total)
    end

  
    def populate_species_names(transformed_obs)
      obs_url = transformed_obs[:observation_url]
      url = "#{SPECIES_DETAIL_URL}#{obs_url}"
      
      response = HTTParty.get(
        url
      )

      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        if result[:organism].present?
          transformed_obs[:scientific_name] = transformed_obs[:accepted_name] = result[:organism][:scientificName] || ''
          transformed_obs[:common_name] = result[:organism][:customName] || ''
          if transformed_obs[:identifications_count] == 0 && transformed_obs[:scientific_name].present?
            transformed_obs[:identifications_count] = 1
          end
        end
        return transformed_obs
      else
        Delayed::Worker.logger.info "Source::GBIF.populate_species_names: #{response}"
      end

    end

    def get_observations()
      biosmart_obs = []
      params = Source::CitSci.dry_initializer.attributes(self)
      api_url = "#{OBS_URL}".gsub(/ID/, params[:project_id])
      (start_dt, end_dt) = params[:"observed_at"].split(/,/, 2)


      response = HTTParty.get(
        api_url,
        query: get_params(),
      )

      Delayed::Worker.logger.info "Source::CitSci.api_url: #{response.request.last_uri.to_s}"
      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        t = Source::CitSci::Transformer.new()
        @total = result[:"hydra:totalItems"]
        result[:"hydra:member"].each do |obs|
          observed_at = obs[:observedAt]

          ## Process data only if observation date falls between the given date range
          if observed_at >= (start_dt.to_time) && observed_at < (end_dt.to_time)
            transformed_obs = t.call(obs)
            validation_result = Source::Schema::ObservationSchema.call(transformed_obs)
            if validation_result.failure?
              Delayed::Worker.logger.info "Source::CitSci.get_observations: #{obs}"
              Delayed::Worker.logger.error 'Source::CitSci.get_observations: ' + 
                "#{validation_result.errors.to_h.merge(unique_id: transformed_obs[:unique_id])}"
              next
            end
            if transformed_obs[:observation_url].present?
              transformed_obs = populate_species_names(transformed_obs)
            else
              transformed_obs[:scientific_name] = transformed_obs[:accepted_name] = transformed_obs[:common_name] = ''
            end
            transformed_obs.delete(:observation_url)

            biosmart_obs.append(transformed_obs)
          else
            Delayed::Worker.logger.info "Skipping record of id(#{obs[:id]}) as observedAt (#{observed_at}) is not in the given date range: (#{start_dt.to_time} - #{end_dt.to_time})"
          end
        end
      else
        @total = 0
        Delayed::Worker.logger.info "Source::CitSci.get_observations: #{response}"
      end
      Delayed::Worker.logger.info "Source::CitSci.get_observations biosmart_obs count: #{biosmart_obs.length}"

      return biosmart_obs
    end
  end
end
