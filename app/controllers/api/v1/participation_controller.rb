require './services/participation'

module Api::V1
  class ParticipationController < ApiController
    def search
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Participation::Fetch.call(search_params) do |result|
        result.success do |participations|
          render json: participations
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end
  end
end 