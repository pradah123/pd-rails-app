require 'timezone_finder'

module Utils
  ABC = 10
  def self.get_utc_time(lat:, lng:, date_s:, time_s:)
    if lat == nil
      raise ArgumentError, 'Please provide a valid lat value'
    end
    if lng == nil
      raise ArgumentError, 'Please provide a valid lng value'
    end
    if date_s == nil
      raise ArgumentError, 'Please provide a valid date string value'
    end
    utc_dttm = date_s
    tf = TimezoneFinder.create
    tz_str = tf.timezone_at(lng: lng, lat: lat) || 
            tz_str = tf.timezone_at(lng: lng, lat: lat) || 
            tz_str = tf.certain_timezone_at(lng: lng, lat: lat)
    if tz_str != nil && time_s != nil
      timezone = TZInfo::Timezone.get(tz_str)
      utc_dttm = timezone.local_to_utc(
        Time.strptime("#{date_s} #{time_s}", '%Y-%m-%d %H:%M')
      )
    end
    
    return utc_dttm.to_s
  end

  def self.get_bounding_box(subregion_polygon)
    west, east = subregion_polygon["coordinates"].map{|co| co.first}.minmax
    south, north = subregion_polygon["coordinates"].map{|co| co.last}.minmax

    return west, east, south, north
  end

  def self.get_center_of_bounding_box(west, east, south, north)
    # ne
    ne = Geokit::LatLng.new(north, east)
    # sw
    sw = Geokit::LatLng.new(south, west)
    return sw.midpoint_to(ne)
  end

  def self.convert_to_seconds(unit:, value:)
    seconds = 0
    if unit == 'year'
      seconds = value * 365.25 * 24 * 3600
    end
    if unit == 'days'
      seconds = value * 24 * 3600
    end
    return seconds
  end

  def self.valid_file?(file_name:)
    return false unless File.file?(file_name)

    line_count = `wc -l #{file_name}`.to_i
    return false unless line_count > 1 ## We need to ignore header line in count
    return true
  end


  # Fetch matching category ranking e.g. kingdom, class, phylum and it's value e.g. animalia, aves etc.
  # for given user friendly category name e.g. from app/views/pages/_category_mapping.json
  def self.get_category_rank_name_and_value(category_name:)
    file = File.open "#{Rails.root}/app/views/pages/_category_mapping.json"
    category_mapping = JSON.load file

    category_mapping.each do |category|
      if category['name'] == category_name
        query = ''
        if category['phylum'].present?
          query += "phylum IN (#{category['phylum'].split(/,/).inspect[1...-1].gsub('"', "'")})"
        end
        if category['class_name'].present?
          query += " OR " unless query.blank?
          query += "class_name IN (#{category['class_name'].split(/,/).inspect[1...-1].gsub('"', "'")})"
        end
        if category['order'].present?
          query += " OR " unless query.blank?
          query += '"order" IN (' + category['order'].split(/,/).inspect[1...-1].gsub('"', "'") +')'
        end
        if category['kingdom'].present?
          query += " OR " unless query.blank?
          query += "kingdom IN (#{category['kingdom'].split(/,/).inspect[1...-1].gsub('"', "'")})"
        end
        return query
      end
    end
    return ''
  end

  def self.get_day_start_time(date_s:)
    return unless date_s.present?
    day_start_time = Date.parse(date_s).strftime("%Y-%m-%d 00:00:00")
    day_end_time   = Date.parse(date_s).strftime("%Y-%m-%d 23:59:59")

    return day_start_time
  end

  def self.get_day_end_time(date_s:)
    return unless date_s.present?
    day_end_time   = Date.parse(date_s).strftime("%Y-%m-%d 23:59:59")

    return day_end_time
  end

  def self.get_months
    month_arr = %w[January February March April May June July August September October November December]
    return month_arr
  end

  # The distance from the center of a square to any one of its four corners can be calculated
  # by taking half the length of one side of the square, squaring that value,
  # doubling the result, then taking the square root of that number.
  def self.get_polygon_radius(polygon_side_length)
    polygon_radius = Math.sqrt(((polygon_side_length/2) ** 2) * 2)
    return polygon_radius
  end

  def self.get_polygon_from_lat_lng(lat, lng, radius = 0.35)
    point = Geokit::LatLng.new lat, lng

    bound = Geokit::Bounds.from_point_and_radius(point, radius, units: :kms)
    sw = bound.sw
    ne = bound.ne
    polygon = {
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
    return polygon
  end

  def self.calculate_polygon_area(coordinates)
    return 0.0 unless coordinates.size > 2

    area = 0.0
    coor_p = coordinates.first
    if coordinates[0].join != coordinates[-1].join
      coordinates.push coordinates[0]
    end
    coordinates[1..].each do |coor|
      area += deg2rad(coor[1] - coor_p[1]) *
              (2 + Math.sin(deg2rad(coor_p[0])) + Math.sin(deg2rad(coor[0])))
      coor_p = coor
    end
    area = (area * 6_378_137 * 6_378_137 / 2.0).abs # 6378137 Earth's radius in meters
    area /= 10_000 #In hectare

    return area
  end

  def self.deg2rad(degrees)
    radians = degrees * Math::PI / 180
    return radians
  end

end
