class CreateMatviewForRegionsObservations < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS regions_observations_matview
    SQL
    execute <<-SQL
      CREATE MATERIALIZED VIEW regions_observations_matview AS
      (
        SELECT
          distinct observations.*,
          obrs.region_id
        FROM
          observations
        INNER JOIN
            observations_regions obrs
        ON
            obrs.observation_id = observations.id
      )
      WITH DATA
    SQL

    add_index :regions_observations_matview, :region_id, name: 'index_regions_observations_matview_on_region_id'
    add_index :regions_observations_matview, :accepted_name, name: 'index_regions_observations_matview_on_accepted_name'
    add_index :regions_observations_matview, :scientific_name, name: 'index_regions_observations_matview_on_scientific_name'
    add_index :regions_observations_matview, :observed_at, name: 'index_regions_observations_matview_on_observed_at'
    add_index :regions_observations_matview, [:id, :region_id], unique: true
  end
end
