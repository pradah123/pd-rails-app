class ObservationsRegionsChanges < ActiveRecord::Migration[7.0]

def change
  add_column :observations_regions, :data_source_id, :integer

  remove_index :observations_regions, name: :observations_regions_ukey

  add_index :observations_regions, [:region_id, :observation_id, :data_source_id],
            unique: true, name: 'observations_regions_ukey'

  ## Need to update data_source_id for existing records in observations_regions table
  #update_sql = "UPDATE observations_regions obsr SET data_source_id = obs.data_source_id FROM 
  #Observations obs where obsr.observation_id = obs.id"  ## 808075

  #ActiveRecord::Base.connection.execute update_sql
end



