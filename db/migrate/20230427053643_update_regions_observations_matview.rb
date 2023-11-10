class UpdateRegionsObservationsMatview < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS regions_observations_matview CASCADE
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
    add_index :regions_observations_matview, :license_code, name: 'index_regions_observations_matview_on_license_code'

    execute <<-SQL
      CREATE MATERIALIZED VIEW taxon_observations_monthly_count_matview AS
      (
        SELECT
          extract(month from observed_at::date)::integer as month,
          extract(year from observed_at::date)::integer as year,
          count(id) as observations_count,
          taxonomy_id,
          region_id
        FROM
          regions_observations_matview
        GROUP BY taxonomy_id,
                 region_id,
                 extract(month from observed_at::date),
                 extract(year from observed_at::date)
      )
      WITH DATA
    SQL
    add_index :taxon_observations_monthly_count_matview, [:region_id, :taxonomy_id, :month, :year], unique: true, name: 'index_taxon_month_year'
    add_index :taxon_observations_monthly_count_matview, :taxonomy_id, name: 'index_taxon_observations_monthly_count_taxonomy_id'
    add_index :taxon_observations_monthly_count_matview, :month, name: 'index_taxon_observations_monthly_count_month'
    add_index :taxon_observations_monthly_count_matview, :year, name: 'index_taxon_observations_monthly_count_year'
  end

end
