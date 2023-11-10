class AddBioscoreToObservations < ActiveRecord::Migration[7.0]
  def change
    add_column :observations, :bioscore, :float, :default => 0

    avg_obs_score = Constant.find_by_name('average_observations_score')&.value || 20
    Observation.where(data_source_id: DataSource.find_by_name('gbif').id).update_all(bioscore: avg_obs_score)
  end
end
