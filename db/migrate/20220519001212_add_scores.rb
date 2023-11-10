class AddScores < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :physical_health_score, :float, default: 0.0
    add_column :regions, :mental_health_score, :float, default: 0.0
    add_column :participations, :physical_health_score, :float, default: 0.0
    add_column :participations, :mental_health_score, :float, default: 0.0
    add_column :contests, :physical_health_score, :float, default: 0.0
    add_column :contests, :mental_health_score, :float, default: 0.0

    Constant.create! name: 'physical_health_score_constant', value: 1379.0 
    Constant.create! name: 'physical_health_score_constant_a', value: 0.33
    Constant.create! name: 'physical_health_score_constant_b', value: 0.43
    Constant.create! name: 'mental_health_score_constant', value: 2804
    Constant.create! name: 'mental_health_score_constant_a', value: 0.5
    Constant.create! name: 'mental_health_score_constant_b', value: 0.51
    Constant.create! name: 'average_hours_per_observation', value: 1.0

  end
end
