require_relative '../common/utils.rb'
require_relative './schema/observation.rb'

module Types
  include Dry.Types()
end

module Source
  class Ebird
    extend Dry::Initializer

    OBS_URL = 'https://api.ebird.org/v2/data/obs/geo/recent'.freeze
    SUB_ID_URL = 'https://api.ebird.org/v2/product/checklist/view/%s'.freeze

    param :species_code_map, reader: :private, default: proc { {} }
    param :loc_id_map, reader: :private, default: proc { {} }
    param :sub_ids, reader: :private, default: proc { [] }

    option :back, reader: :private, type: Types::Coercible::Integer
    option :lat, reader: :private, type: Types::Coercible::Float
    option :lng, reader: :private, type: Types::Coercible::Float
    option :dist, reader: :private, type: Types::Coercible::Integer
    option :sort, default: proc { 'date' }, reader: :private, type: Types::Strict::String
    
    def get_params()
      params = Source::Ebird.dry_initializer.attributes(self)
      return params
    end

    def populate_structures()
      # response = HTTParty.get(
      #     'https://jsonkeeper.com/b/H7JA'
      # )
      response = HTTParty.get(
        OBS_URL,
        query: get_params(),
        headers: {'X-eBirdApiToken' => ENV.fetch('EBIRD_TOKEN')},
        # debug_output: $stdout
      )
      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        result.each do |r|
          @species_code_map[r[:speciesCode]] = {
            sname: r[:sciName],
            cname: r[:comName]
          }
          @loc_id_map[r[:locId]] = {
            lat: lat,
            lng: lng
          }
          @sub_ids.append(r[:subId])
        end
      end
    end

    def transform(obs, loc_id, creator_name)
      species_code = obs[:speciesCode]
      if @loc_id_map[loc_id].blank?
        return nil
      end
      lat = @loc_id_map[loc_id][:lat]
      lng = @loc_id_map[loc_id][:lng]
      scientific_name = species_code
      common_name = nil
      if @species_code_map[species_code].present?
        scientific_name = @species_code_map[species_code][:sname]
        common_name = @species_code_map[species_code][:cname]
      end
      identifications_count = (scientific_name.present? ? 1 : 0)
      (date, time) = obs[:obsDt].split(' ')
      return {
        unique_id: obs[:obsId],
        lat: lat,
        lng: lng,
        creator_name: creator_name,
        scientific_name: scientific_name,
        common_name: common_name,
        observed_at: ::Utils.get_utc_time(
          lat: lat, lng: lng, date_s: date, time_s: time
        ),
        accepted_name: scientific_name,
        identifications_count: identifications_count
      }
    end

    def get_observations()
      biosmart_obs = []
      populate_structures()
      @sub_ids.uniq.each do |sub_id|
        response = HTTParty.get(
          SUB_ID_URL % [sub_id],
          headers:{'X-eBirdApiToken' => ENV.fetch('EBIRD_TOKEN')},
          # debug_output: $stdout
        )
        if response.success? && !response.body.nil?
          checklist_result = JSON.parse(response.body, symbolize_names: true)
          loc_id = checklist_result[:locId]
          creator_name = checklist_result[:userDisplayName]
          checklist_result[:obs].each do |obs|
            transformed_obs = transform(obs, loc_id, creator_name)
            if transformed_obs.present?
              validation_result = Source::Schema::ObservationSchema.call(transformed_obs)
              if validation_result.failure?
                Delayed::Worker.logger.info "Source::Ebird.get_observations: #{obs}"
                Delayed::Worker.logger.error 'Source::Ebird.get_observations: ' + 
                  "#{validation_result.errors.to_h.merge(unique_id: transformed_obs[:unique_id])}"
                next
              end
              biosmart_obs.push(transformed_obs)
            else
              Delayed::Worker.logger.info "--- #{loc_id}, #{obs[:speciesCode]} ---"
              Delayed::Worker.logger.info "#{@loc_id_map}"
              Delayed::Worker.logger.info "#{@species_code_map}"
            end
          end
        end
      end
      Delayed::Worker.logger.info "Source::Ebird.get_observations biosmart_obs count: #{biosmart_obs.length}"

      return biosmart_obs
    end
  end
end
