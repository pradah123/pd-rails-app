class AddUniqueIndexToGbifObservationsMatview < ActiveRecord::Migration[7.0]
  def change
    add_index :gbif_observations_matview, [:id, :region_id], unique: true
  end
end
