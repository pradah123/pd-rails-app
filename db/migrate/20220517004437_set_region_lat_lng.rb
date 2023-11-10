class SetRegionLatLng < ActiveRecord::Migration[6.1]
  def change
    Region.all.each { |r| r.set_lat_lng }
  end
end
