class AddBaseRegionIdAndSizeToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :base_region_id, :integer
    add_column :regions, :size, :float
    add_index :regions, :base_region_id
  end
end
