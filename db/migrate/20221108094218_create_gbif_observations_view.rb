class CreateGbifObservationsView < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      CREATE MATERIALIZED VIEW gbif_observations_matview AS
      (
        SELECT
          observations.*,
          obrs.region_id
        FROM
          observations
        INNER JOIN
            observations_regions obrs
        ON
            obrs.observation_id = observations.id
        WHERE
            obrs.data_source_id IN (SELECT id FROM data_sources WHERE name='gbif')
      )
      WITH DATA
    SQL

    add_index :gbif_observations_matview, :region_id, name: 'index_gbif_observations_matview_on_region_id'
    add_index :gbif_observations_matview, :accepted_name, name: 'index_gbif_observations_matview_on_accepted_name'
    add_index :gbif_observations_matview, :scientific_name, name: 'index_gbif_observations_matview_on_scientific_name'
    add_index :gbif_observations_matview, :observed_at, name: 'index_gbif_observations_matview_on_observed_at'
  end
end
