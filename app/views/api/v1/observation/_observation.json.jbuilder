# frozen_string_literal: true

json.call(observation, 
          :id,
          :lat,
          :lng,
          :observed_at,
          :scientific_name,
          :common_name,
          :accepted_name,
          :identifications_count,
          :creator_name,
          :creator_id,
          :address
        )
json.images observation.observation_images,
            partial: 'api/v1/observation/observation_image',
            as: :observation_image
# json.array! observation.observation_images do |observation_image|
#   json.partial! partial: 'api/v1/observation/observation_image', observation_image: observation_image
# end
