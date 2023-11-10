class ObservationsRegion < ActiveRecord::Migration[7.0]
  def change
    change_table :observations_regions do |t|
      t.belongs_to :observation, index: true,  foreign_key: true 
      t.belongs_to :region, index: true, foreign_key: true
       
    end
  end
end
