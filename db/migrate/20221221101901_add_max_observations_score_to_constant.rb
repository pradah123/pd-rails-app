class AddMaxObservationsScoreToConstant < ActiveRecord::Migration[7.0]
  def change
    Constant.create! name: 'max_observations_score', value: 300
  end
end
