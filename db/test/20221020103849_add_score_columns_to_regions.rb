class AddScoreColumnsToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :total_vs_greater_region_observations_score, :float
    add_column :regions, :total_vs_locality_observations_score, :float
    add_column :regions, :this_year_vs_total_observations_score, :float
    add_column :regions, :last_2years_vs_total_observations_score, :float

    add_column :regions, :total_vs_greater_region_species_score, :float
    add_column :regions, :total_vs_locality_species_score, :float
    add_column :regions, :this_year_vs_total_species_score, :float
    add_column :regions, :last_2years_vs_total_species_score, :float

    add_column :regions, :total_vs_greater_region_activity_score, :float
    add_column :regions, :total_vs_locality_activity_score, :float
    add_column :regions, :this_year_vs_total_activity_score, :float
    add_column :regions, :last_2years_vs_total_activity_score, :float
  end
end
