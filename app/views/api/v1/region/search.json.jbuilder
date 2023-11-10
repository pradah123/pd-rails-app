# frozen_string_literal: true

json.array! @regions do |region|
  json.partial! partial: 'api/v1/region/region_info', region: region
  json.partial! partial: 'api/v1/region/region_metrics', region: region
end
