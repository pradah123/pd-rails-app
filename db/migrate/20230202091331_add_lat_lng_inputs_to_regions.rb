class AddLatLngInputsToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :lat_input, :float
    add_column :regions, :lng_input, :float
    add_column :regions, :polygon_side_length, :float
  end
end
