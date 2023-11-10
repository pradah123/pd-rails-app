require_relative './gbif/transformer.rb'
require_relative './schema/observation.rb'

module Types
  include Dry.Types()
end

module Source
  class GBIF
    extend Dry::Initializer

    API_URL = 'https://api.gbif.org/v1/occurrence/search'.freeze
    GBIF_RECORDS_LIMIT = 1_020_0  # Limit the number of records to fetch in one request
    
    param :count, default: proc { nil }, reader: :private

    option :geometry, reader: :private, type: Types::Strict::String
    option :eventDate, reader: :private, type: Types::Strict::String
    option :offset, default: proc { 1 }, reader: :private, type: Types::Strict::Integer
    option :limit, default: proc { 300 }, reader: :private, type: Types::Strict::Integer


    DATASET_MAP = {
      '50c9509d-22c7-4a22-a47d-8c48425ef4a7' => 'inaturalist', 
      '8a863029-f435-446a-821e-275f4f641165' => 'observation.org',
      '4fa7b334-ce0d-4e88-aaae-2e0c138d049e' => 'ebird',
      'e3ce628e-9683-4af7-b7a9-47eef785d3bb' => 'qgame'
    }

    def self.get_dataset_keys()
      return DATASET_MAP.keys
    end

    def self.get_dataset_name(dataset_key)
      return DATASET_MAP[dataset_key]      
    end

    def get_params()
      params = Source::GBIF.dry_initializer.attributes(self)
      params.delete(:count)
      params.delete(:eventdate)

      return params
    end

    def get_event_date
      params = Source::GBIF.dry_initializer.attributes(self)
      return params[:eventdate]
    end

    def get_api_url
      api_url = "#{API_URL}?"
      ## Need to explicilty add dataset_key parameter for each dataset in the url itself
      ## instead of passing them as params in query as HTTPParty converts them into
      ## 'dataset_key[]=' format which is not acceptable by gbif
      ## URL example with multiple occurences of dataset_key  https://api.gbif.org/v1/occurrence/search?dataset_key=50c9509d-22c7-4a22-a47d-8c48425ef4a7&dataset_key=8a863029-f435-446a-821e-275f4f641165&dataset_key=4fa7b334-ce0d-4e88-aaae-2e0c138d049e&dataset_key=e3ce628e-9683-4af7-b7a9-47eef785d3bb&eventdate=2021-12-11%2C2022-08-25&offset=0&limit=300
      DATASET_MAP.each_key do |k|
        api_url = api_url + "dataset_key=#{k}&"
      end
      ## Need to explicitly add evenDate parameter in the url as HTTPParty converts it to small case
      event_date = get_event_date
      api_url = api_url + "eventDate=#{event_date}"
      return api_url
    end

    def increment_page()
        @offset += limit
    end

    def done()
      return  @count.present? &&
              (@offset >= @count)
    end

    def get_observations(fetch_count: false)
      biosmart_obs = []
      event_date = get_event_date

      response = HTTParty.get(
        get_api_url,
        query: get_params()
      )
      Delayed::Worker.logger.info "Source::GBIF.api_url: #{response.request.last_uri.to_s}"

      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        @count = result[:count]
        if fetch_count.present?
          return (@count.present? ? @count : 0)
        end
        @count = GBIF_RECORDS_LIMIT if @count > GBIF_RECORDS_LIMIT

        t = Source::GBIF::Transformer.new()
        (start_dt, end_dt) = event_date.split(/,/, 2)

        result[:results].each do |gbif_obs|
          observed_at = gbif_obs[:eventDate]

          ## Sometimes gbif gives wrong eventDate which does not fall in the given date range but we get 
          ## correct year, month and day, so generate eventDate from these
          if ((observed_at < start_dt.to_time || observed_at > (end_dt.to_time + 1.days)) &&
             gbif_obs[:year].present? && gbif_obs[:month].present? && gbif_obs[:day].present?)
            observed_at = "#{gbif_obs[:year]}-#{gbif_obs[:month]}-#{gbif_obs[:day]}".to_time.to_s
            gbif_obs[:eventDate] = observed_at
          end

          ## Process data only if observation date falls between the given date range
          ## We are being extra cautious in case we don't get year, month, day in above condition
          if observed_at >= (start_dt.to_time - 60) && observed_at < (end_dt.to_time + 1.days)
            ## Process data only if datasetkey matches with the required set
            if Source::GBIF.get_dataset_name(gbif_obs[:datasetKey]).present?
              transformed_obs = t.call(gbif_obs)

              if transformed_obs.present?
                validation_result = Source::Schema::ObservationSchema.call(transformed_obs)

                if validation_result.failure?
                  Delayed::Worker.logger.info "Source::GBIF.get_observations: #{transformed_obs}"
                  Delayed::Worker.logger.error 'Source::GBIF.get_observations: ' + 
                    "#{validation_result.errors.to_h.merge(unique_id: transformed_obs[:unique_id])}"
                  next
                end
                biosmart_obs.append(transformed_obs)
              end
            end
          else
            Delayed::Worker.logger.info "Skipping record of observation(#{gbif_obs[:catalogNumber]}) as eventDate 
            (#{observed_at}) is not in the given date range: (#{start_dt.to_time} - #{end_dt.to_time})"
          end
        end
      else
        @count = 0
        Delayed::Worker.logger.info "Source::GBIF.get_observations: #{response}"
      end
      Delayed::Worker.logger.info "Source::GBIF.get_observations biosmart_obs count: #{biosmart_obs.length}"
      return biosmart_obs
    end
  end
end
