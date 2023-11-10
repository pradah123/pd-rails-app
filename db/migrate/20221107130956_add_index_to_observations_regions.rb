class AddIndexToObservationsRegions < ActiveRecord::Migration[7.0]
  def change
    add_index :observations_regions, [:region_id, :data_source_id],
    name: 'index_observations_regions_on_region_id_data_source_id'
  end
end
