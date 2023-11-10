class AddFlagsToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :create_neighboring_region_subregions_for_ebird, :boolean, default: false
    add_column :regions, :fetch_neighboring_region_data, :boolean, default: false
  end
end
