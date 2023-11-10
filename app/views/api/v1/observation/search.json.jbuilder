# frozen_string_literal: true

json.array! @observations do |observation|
  json.partial! partial: 'api/v1/observation/observation', observation: observation
end
