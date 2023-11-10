# frozen_string_literal: true

json.partial! partial: 'api/v1/region/region_info', region: participation.region
json.call(participation,
          :species_count,
          :observations_count,
          :people_count,
          :physical_health_score,
          :mental_health_score,
          :identifications_count
        )
