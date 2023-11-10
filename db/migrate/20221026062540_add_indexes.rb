class AddIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :observations, :accepted_name
    add_index :observations, :observed_at
    add_index :observations, :creator_name
    
    add_index :observations_regions, :data_source_id
    add_index :observations_regions, :region_id
  end
end
