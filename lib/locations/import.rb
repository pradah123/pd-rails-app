require 'csv'
require_relative '../source/gbif.rb'

module ImportLocations
  def self.import_from_csv(file_name:)
    count = 1
    write_parameters = { write_headers: true, headers: ["Hotel Name", "Hotel Address Text", "Hotel Address City",
                                                        "Hotel  Address  ZipCode", "Base Location", "Greater Location",
                                                        "Base Polygon", "Greater Polygon", "Base Count", "Greater Count"] }
    CSV.open('new_list.csv', 'w+:UTF-16:utf-8', :write_headers=> true, 
      :headers => ["Hotel  ShortCode","Hotel Name","Hotel Segment","Hotel Brand","Number of rooms","Hotel Address Text","Hotel Address City","Hotel  Address  ZipCode","Base Location","Greater Location","Base Polygon","Greater Polygon","Base Count","Greater Count"]) do |new_csv|

      CSV.foreach(file_name, headers: true, col_sep: ",", skip_blanks: true, encoding: "bom|utf-8", quote_char: nil) do |row|

        address = "#{row['Hotel Address Text']}, #{row['Hotel Address City']}, #{row['Hotel  Address  ZipCode']}"
        puts address

        url = Addressable::URI.parse("https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&key=AIzaSyBFT4VgTIfuHfrL1YYAdMIUEusxzx9jxAQ").display_uri.to_s
        response = HTTParty.get(url)
        result = JSON.parse(response.body)
        next unless result['results'].present?
        location =  result['results'][0]['geometry']['location'] 
        point = Geokit::LatLng.new location['lat'], location['lng']

        bound = Geokit::Bounds.from_point_and_radius(point, 1, units: :kms)
        sw = bound.sw
        ne = bound.ne
        puts bound.sw.lng
        base_polygon = {
        "type" => "Polygon",
        "coordinates" => [
          # nw
          [sw.lng, ne.lat],
          # ne
          [ne.lng, ne.lat],
          # se
          [ne.lng, sw.lat],
          # sw
          [sw.lng, sw.lat],
          # nw to close polygon
          [sw.lng, ne.lat]
        ]}
        puts base_polygon.to_json
        gbif_polygon = Region.get_polygon_from_raw_polygon_json base_polygon.to_json
        puts gbif_polygon

        ends_at = Time.now
        starts_at = ends_at - Utils.convert_to_seconds(unit:'year', value: 3)

        params = { offset: 0,
          limit: 1,
          geometry: gbif_polygon,
          eventDate:  "#{starts_at.strftime('%Y-%m-%d')},#{ends_at.strftime('%Y-%m-%d')}"
        }

        gbif = ::Source::GBIF.new(**params)
        count = gbif.get_observations(fetch_count: true) || 0
        puts "GBIF count: #{count}"
        with_multiplier = 12.5
        scaled_ne = bound.center.endpoint(
          bound.center.heading_to(bound.ne), 
          bound.center.distance_to(bound.ne, units: :kms) * with_multiplier, 
          units: :kms
        )
        scaled_sw = bound.center.endpoint(
          bound.center.heading_to(bound.sw), 
          bound.center.distance_to(bound.sw, units: :kms) * with_multiplier, 
          units: :kms
        )
        scaled_polygon = {
          "type" => "Polygon",
          "coordinates" => [
            # nw
            [scaled_sw.lng, scaled_ne.lat],
            # ne
            [scaled_ne.lng, scaled_ne.lat],
            # se
            [scaled_ne.lng, scaled_sw.lat],
            # sw
            [scaled_sw.lng, scaled_sw.lat],
            # nw to close polygon
            [scaled_sw.lng, scaled_ne.lat]
          ]}
        puts ""
        puts "scaled : #{scaled_polygon.to_json}"
        gbif_scaled_polygon = Region.get_polygon_from_raw_polygon_json scaled_polygon.to_json
        puts gbif_scaled_polygon
        params = { offset: 0,
          limit: 1,
          geometry: gbif_scaled_polygon,
          eventDate:  "#{starts_at.strftime('%Y-%m-%d')},#{ends_at.strftime('%Y-%m-%d')}"
        }

        gbif = ::Source::GBIF.new(**params)
        scaled_count = gbif.get_observations(fetch_count: true) || 0
        puts "gbif scaled count: #{scaled_count}"
        row['Base Location'] ||= "#{location['lat']}, #{location['lng']}"
        row['Greater Location'] ||= ''
        row['Base Polygon'] ||= base_polygon.to_json
        row['Greater Polygon'] ||= scaled_polygon.to_json
        row['Base Count'] ||= count
        row['Greater Count'] ||= scaled_count

        new_csv << row
      end
    end
  end
end
