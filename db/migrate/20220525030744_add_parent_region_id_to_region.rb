class AddParentRegionIdToRegion < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :parent_region_id, :integer
  end
end
