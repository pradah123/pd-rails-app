class TaxonObservationsMonthlyCountMatview < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS taxon_observations_monthly_count_matview
    SQL
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
