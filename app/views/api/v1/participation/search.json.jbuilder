json.array! @participations do |participation|
  json.partial! partial: 'api/v1/participation/participation', participation: participation
end
