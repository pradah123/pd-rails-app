# frozen_string_literal: true

json.partial! partial: 'api/v1/region/region_info', region: @region
json.partial! partial: 'api/v1/region/region_metrics', region: @region
json.merge! @region.get_region_scores
