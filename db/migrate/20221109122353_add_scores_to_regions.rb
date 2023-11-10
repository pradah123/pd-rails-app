class AddScoresToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :bio_value, :float, default: 0.0
    add_column :regions, :species_diversity_score, :float, default: 0.0
    add_column :regions, :species_trend, :float, default: 0.0
    add_column :regions, :monitoring_score, :float, default: 0.0
    add_column :regions, :monitoring_trend, :float, default: 0.0
    add_column :regions, :community_score, :float, default: 0.0
    add_column :regions, :community_trend, :float, default: 0.0
  end
end
