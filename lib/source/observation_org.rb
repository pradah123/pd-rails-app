require_relative './observation_org/auth.rb'
require_relative './observation_org/transformer.rb'

module Types
  include Dry.Types()
end

module Source
  class ObservationOrg
    extend Dry::Initializer

    API_URL = 'https://observation.org/api/v1/locations/%s/observations'.freeze

    param :count, default: proc { 0 }, reader: :private

    option :date_after, reader: :private, type: Types::Strict::String
    option :date_before, reader: :private, type: Types::Strict::String
    option :limit, reader: :private, type: Types::Coercible::Integer
    option :offset, reader: :private, type: Types::Coercible::Integer
    option :location_id, reader: :private, type: Types::Coercible::Integer
    option :species_group, optional: true, reader: :private, type: Types::Strict::String

    def get_params()
      params = Source::ObservationOrg.dry_initializer.attributes(self)
      params.delete(:count)
      params.delete(:location_id)
      
      return params
    end
    
    def get_observations()
      access_token = Source::ObservationOrg::Auth.get_access_token()
      biosmart_obs = []
      response = HTTParty.get(
        API_URL % [@location_id],
        query: get_params(),
        headers: {
            'Authorization' => "Bearer #{access_token}"
        },
        # debug_output: $stdout
      )
      Delayed::Worker.logger.info "Source::ObservationOrg.api_url: #{response.request.last_uri.to_s}"

      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        t = Source::ObservationOrg::Transformer.new()
        @count = result[:count]
        result[:results].each do |obs_org_obs|
          transformed_obs = t.call(obs_org_obs)
          validation_result = Source::Schema::ObservationSchema.call(transformed_obs)
          if validation_result.failure?
            Delayed::Worker.logger.error "Source::ObservationOrg.get_observations: #{obs_org_obs}"
            Delayed::Worker.logger.error 'Source::ObservationOrg.get_observations: ' + 
              "#{validation_result.errors.to_h.merge(unique_id: transformed_obs[:unique_id])}"
            next
          end
          biosmart_obs.push(transformed_obs)
        end
      else
        @count = 0
        Delayed::Worker.logger.info "Source::ObservationOrg.get_observations: #{response}"
      end
      Delayed::Worker.logger.info "Source::ObservationOrg.get_observations biosmart_obs count: #{biosmart_obs.length}"

      return biosmart_obs
    end

    def done()
        return @offset >= @count
    end

    def increment_offset()
      @offset += @limit
    end

  end
end
