require 'csv'
require_relative '../source/gbif.rb'

module ImportLocations
  def self.import_from_csv(file_name: , create_regions: false, contests: nil)

    count = 1
    write_parameters = { write_headers: true, headers: ["Country","Name","Location - address",
                                                        "Location - lat, long","Description",
                                                        "Header","LOGO","URL","Base Polygon", 
                                                        "Greater Polygon", 
                                                        "Base Count", 
                                                        "Greater Count"
                                                        ] }
    CSV.open('nature_positive_universities_with_0.35km_radius.csv', 'w+:UTF-16:utf-8', :write_headers=> true, 
      :headers => ["Country","Name","Location - address","Location - lat, long","Description",
        "Header","Logo","URL", "Base Polygon", 
        "Greater Polygon", 
        "Base Count", 
        "Greater Count"
        ]) do |new_csv|

      CSV.foreach(file_name, headers: true, col_sep: ",", skip_blanks: true, encoding: "bom|utf-8", quote_char: "\"") do |row|

        address = "#{row['Country']}, #{row['Name']}, #{row['Location - address']}, #{row['Location - lat, long']}"

        # url = Addressable::URI.parse("https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&key=AIzaSyBFT4VgTIfuHfrL1YYAdMIUEusxzx9jxAQ").display_uri.to_s
        # response = HTTParty.get(url)
        # result = JSON.parse(response.body)
        # next unless result['results'].present?
        # location =  result['results'][0]['geometry']['location'] 
        (lat, lng) = row['Location - lat, long'].split(/[\s, ,]/, 2)
        puts "lat, lng: #{lat.strip}, #{lng.strip}"
        # break

        point = Geokit::LatLng.new lat.strip, lng.strip

        bound = Geokit::Bounds.from_point_and_radius(point, 0.7, units: :kms)
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
          ]
        }
        puts base_polygon.to_json
        gbif_polygon = Region.get_polygon_from_raw_polygon_json base_polygon.to_json
        # puts gbif_polygon

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
        # puts "scaled : #{scaled_polygon.to_json}"
        gbif_scaled_polygon = Region.get_polygon_from_raw_polygon_json scaled_polygon.to_json
        # puts gbif_scaled_polygon
        params = { offset: 0,
          limit: 1,
          geometry: gbif_scaled_polygon,
          eventDate:  "#{starts_at.strftime('%Y-%m-%d')},#{ends_at.strftime('%Y-%m-%d')}"
        }

        gbif = ::Source::GBIF.new(**params)
        scaled_count = gbif.get_observations(fetch_count: true) || 0
        puts "gbif scaled count: #{scaled_count}"
        row['Base Polygon'] ||= base_polygon.to_json
        row['Greater Polygon'] ||= scaled_polygon.to_json
        row['Base Count'] ||= count
        row['Greater Count'] ||= scaled_count
        puts create_regions
        if create_regions.present? && create_regions == "true"
          params = {}
          params[:name] = row['Name']
          params[:description] = row['Description']
          params[:logo_image_url] = row['LOGO']
          params[:region_url] = row['URL']
          params[:header_image_url] = row['Header']
          params[:raw_polygon_json] = "[#{base_polygon.to_json}]"
          region = Region.new params
          if region.save!
            puts "Added region: #{region.name}"
          else 
            puts "Error in adding region: #{params[:name]}"
          end
        end
        if contests
          region = Region.find_by_name(row['Name'])
          puts contests

          contests = contests.split(',')
          if region.present?
            contests.each do |c|
              #{}c = c.strip
              puts "Adding contest: #{c} to participation"
              params = {}
              params[:region_id] = region.id
              params[:contest_id] = Contest.find_by_title(c).id
              params[:status] = 'accepted'
              puts params
              participation = Participation.new params
              if participation.save!
                puts "Added participation: #{participation.id}"
                participation.data_sources << DataSource.where.not(name: ['ebird', 'observation.org', 'gbif'])
              else 
                puts "Error in adding participation for region #{params[:region_id]}, and contest: #{params[:contest_id]} "
              end
            end
          end
        end

        new_csv << row
      end
    end
  end
end
