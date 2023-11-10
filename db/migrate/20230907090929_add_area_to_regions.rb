class AddAreaToRegions < ActiveRecord::Migration[7.0]
  def up
    add_column :regions, :polygon_area, :float, default: 0.0
  end
  def down
    remove_column :regions, :polygon_area
  end
end
