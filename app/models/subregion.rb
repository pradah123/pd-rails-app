class Subregion < ApplicationRecord
  belongs_to :region
  belongs_to :data_source
  belongs_to :data_source_new
  after_save :update_geometry

  enum status: [:stopped, :processing]
  enum fetch_every: [:fifteen_minutes, :thirty_minutes, :one_hour, :two_hours, :four_hours, :eight_hours]

  def contains? lat, lng
    json = JSON.parse raw_polygon_json
    return false if json['coordinates'].blank?
    points = json['coordinates'].map { |c| Geokit::LatLng.new c[1], c[0] }
    polygon = Geokit::Polygon.new(points)

    return polygon.contains?(Geokit::LatLng.new lat, lng)
  end

  #
  #  function called by a subregion job to
  #  fetch data and create or update observations
  #

  def fetch_and_store_observations
    return if region.child_regions.count>0 # no need to fetch for parent regions
    return if processing? # if this subregion is already being fetched, don't duplicate the job
    processing!
    data_source_new.fetch_and_store_observations
    not_processing!
  end

  #
  # considering the fetch_every parameter, compute if 
  # the subregion needs to be fetched at the moment.
  #

  def should_fetch_now hour, min
    if fifteen_minutes?
      true 
    elsif thirty_minutes?
      (min/15)%2==0
    elsif one_hour?
      min/15==0
    elsif two_hours?    
      min/15==0 && hour%2==0
    elsif four_hours?
      min/15==0 && hour%4==0
    elsif eight_hours?
      min/15==0 && hour%8==0  
    end
    false  
  end

  def get_query_parameters
    data_source.get_query_parameters self
  end  

  def update_geometry
    return unless parent_subregion_id.nil?
    return if raw_polygon_json.nil? 

    polygon_geojson = JSON.parse raw_polygon_json
    return if polygon_geojson['coordinates'].nil? # if theres no polygon coordinates present, can't compute the subregions

    #
    # get centre of the polygon
    #
    
    lats = polygon_geojson['coordinates'].map { |c| c[1] }
    lngs = polygon_geojson['coordinates'].map { |c| c[0] }    
    lat_min = lats.min
    lat_max = lats.max
    lng_min = lngs.min
    lng_max = lngs.max
    centre_lat = 0.5*(lat_max+lat_min)
    centre_lng = 0.5*(lng_max+lng_min)

    #
    # make coordinates relative to the centre
    # 
    lats = lats.map { |lat| lat - centre_lat }
    lngs = lngs.map { |lng| lng - centre_lng }

    max_dlat = lats.map { |lat| lat.abs }.max
    max_dlng = lngs.map { |lng| lng.abs }.max

    #
    # get radius of circle which contains the smallest square 
    # which can contain the polygon
    #

    centre = Geokit::LatLng.new centre_lat, centre_lng
    top_right_corner = Geokit::LatLng.new centre_lat+max_dlat, centre_lng+max_dlng
    radius_km = centre.distance_to top_right_corner, units: :kms


    if max_radius_km.nil? || radius_km<=max_radius_km

      #
      # just one circle which encompasses the region is enough.
      #
      self.update_columns lat: centre_lat, lng: centre_lng, radius_km: radius_km

    else
    
      #
      # if the region is too large, tesselate the circle which encompasses the region
      # with smaller circles no larger than the maximum allowed radius.
      #

      n_circles_per_edge = ( (2*radius_km / max_radius_km) / Math.sqrt(2) ).ceil
      dlat = 2*max_dlat / n_circles_per_edge
      dlng = 2*max_dlng / n_circles_per_edge
      radius_km_small_circles = radius_km / n_circles_per_edge

      lat_circle = lat_circle0 = centre_lat - max_dlat + 0.5*dlat
      lng_circle = centre_lng - max_dlng + 0.5*dlng

      new_subregions = []

      #
      # loop over all sub circles
      #

      n_circles_per_edge.times do |ilng|
        lat_circle = lat_circle0
        n_circles_per_edge.times do |ilat|
          circle = { lat: lat_circle, lng: lng_circle }
          new_subregions.push circle
          lat_circle += dlat
        end
        lng_circle += dlng  
      end

      #
      # with the exception of the first circle (the data is contained in this subregion object),
      # create subregions for each subcircle, and reference them to this region via the 
      # parent_subregion_id field
      #

      new_subregions.each_with_index do |s,i|
        if i==0
          update_column :lat, s[:lat]
          update_column :lng, s[:lng]
          update_column :radius_km, radius_km_small_circles
        else            
          Subregion.create! region_id: region_id, parent_subregion_id: id, 
            data_source_id: data_source_id, raw_polygon_json: raw_polygon_json, 
            lat: s[:lat], lng: s[:lng], radius_km: radius_km_small_circles
        end 
      end

    end

  end

  rails_admin do
    list do
      field :id
      field :region          
      field :data_source
      field :lat
      field :lng
      field :radius_km
      field :max_radius_km
      field :raw_polygon_json
      field :created_at      
    end
    edit do 
      field :region          
      field :data_source
      field :lat
      field :lng
      field :radius_km
      field :max_radius_km
      field :raw_polygon_json 
    end
    show do 
      field :id
      field :region          
      field :data_source
      field :lat
      field :lng
      field :radius_km
      field :max_radius_km
      field :raw_polygon_json
      field :created_at  
    end  
  end

end
