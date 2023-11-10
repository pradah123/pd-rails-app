class AddFieldsToSubregion < ActiveRecord::Migration[6.1]
  def change
    add_column :subregions, :lat_min, :float
    add_column :subregions, :lat_max, :float
    add_column :subregions, :lng_min, :float
    add_column :subregions, :lng_max, :float
    add_column :subregions, :centre_lat, :float
    add_column :subregions, :centre_lng, :float
    add_column :subregions, :radius_km, :float
    add_column :subregions, :max_radius_km, :float, default: 50
  end
end
