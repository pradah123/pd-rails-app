class UpdateRegionAndContestColumnsDefault < ActiveRecord::Migration[7.0]
  def change
    change_column :regions, :fetch_neighboring_region_data, :boolean, null: false
    change_column :regions, :create_neighboring_region_subregions_for_ebird, :boolean, null: false
    change_column :contests, :fetch_neighboring_region_data, :boolean, null: false
  end
end
