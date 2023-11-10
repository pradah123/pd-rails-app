class RegionSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :description, :logo_image_url, :logo_image, :header_image_url,
             :header_image, :raw_polygon_json, :region_url, :bioscore, :lat, :lng,
             :lat_input, :lng_input, :polygon_side_length, :status, :slug,
             :observations_count, :species_count, :people_count, :identifications_count,
             :physical_health_score, :mental_health_score,
             :subscription, :display_flag

  # attribute :polygon do |object|
  #   object.get_polygon_json
  # end
end
