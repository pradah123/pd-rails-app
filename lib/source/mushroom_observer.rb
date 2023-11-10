require_relative './mushroom_observer/transformer.rb'
require_relative './schema/observation.rb'

module Types
  include Dry.Types()
end

module Source
  class MushroomObserver
    extend Dry::Initializer

    API_URL = 'https://mushroomobserver.org/api2/observations'.freeze
    
    param :number_of_pages, default: proc { 1 }, reader: :private

    option :has_location, default: proc { true }, reader: :private, type: Types::Strict::Bool    
    option :detail, default: proc { 'high' }, reader: :private, type: Types::Strict::String
    option :format, default: proc { 'json' }, reader: :private, type: Types::Strict::String
    option :page, default: proc { 1 }, reader: :private, type: Types::Strict::Integer
    option :north, reader: :private, type: Types::Coercible::Float
    option :south, reader: :private, type: Types::Coercible::Float
    option :east, reader: :private, type: Types::Coercible::Float
    option :west, reader: :private, type: Types::Coercible::Float
    option :date, reader: :private, type: Types::Strict::String

    def get_params()
      params = Source::MushroomObserver.dry_initializer.attributes(self)
      params.delete(:number_of_pages)

      return params
    end

    def increment_page()
        @page += 1
    end

    def done()
        return @page > @number_of_pages
    end

    def get_observations()
      biosmart_obs = []
      api_url = "#{API_URL}?api_key=#{ENV.fetch('MUSHROOM_OBSERVER_API_KEY')}"
      response = HTTParty.get(
        api_url,
        query: get_params(),
        headers: {
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ' + 
                            'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 ' + 
                            'Safari/537.36'
        },
        debug_output: $stdout
      )
      Delayed::Worker.logger.info "Source::MushroomObserver.api_url: #{response.request.last_uri.to_s}"
      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        @number_of_pages = result[:number_of_pages]
        t = Source::MushroomObserver::Transformer.new()
        result[:results].each do |mo_obs|
          transformed_obs = t.call(mo_obs)
          validation_result = Source::Schema::ObservationSchema.call(transformed_obs)
          if validation_result.failure?
            Delayed::Worker.logger.info "Source::MushroomObserver.get_observations: #{mo_obs}"
            Delayed::Worker.logger.error 'Source::MushroomObserver.get_observations: ' + 
              "#{validation_result.errors.to_h.merge(unique_id: transformed_obs[:unique_id])}"
            next
          end
          biosmart_obs.append(transformed_obs)
        end
      else
        @number_of_pages = 0
        Delayed::Worker.logger.info "Source::MushroomObserver.get_observations: #{response}"
      end
      Delayed::Worker.logger.info "Source::MushroomObserver.get_observations biosmart_obs count: #{biosmart_obs.length}"
      sleep 5
      return biosmart_obs
    end
  end
end
