class NeighboringRegion
  # initialize(Region, Int) -> Void

  attr_reader :size, :existing_region, :base_region

  def initialize(base_region, current_region = nil, size)
    @base_region = base_region
    @size = size
    if (current_region&.size.present?)
      @existing_region = current_region # Requires while updating neighboring region
    else
      @existing_region = @base_region.neighboring_regions&.where(size: @size).first
    end
  end

  # get_region() -> Region
  def get_region()
    # NOTE: If neighboring region does not exists, create new region
    r = @existing_region || Region.new()
    r.size = @size
    r.name = name()
    r.base_region_id = @base_region.id
    r.raw_polygon_json = get_polygon_geojson()

    return r    
  end

  # name() -> String
  def name()
    name_postfix = @size.to_s.gsub!(/\.?0+$/, "") || @size
    return "#{@base_region.name} #{name_postfix}X"
  end

  # get_polygon_geojson() -> String
  def get_polygon_geojson()
    scaled_polygons = @base_region.scaled_bbox_geojson(with_multiplier: @size)
    
    return scaled_polygons.to_json
  end

end
