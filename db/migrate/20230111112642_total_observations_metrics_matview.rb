class TotalObservationsMetricsMatview < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS total_observations_metrics_matview
    SQL
    execute <<-SQL
      CREATE MATERIALIZED VIEW total_observations_metrics_matview AS
      (
        SELECT max(total_observations_count) total_observations_count,
               max(total_species_count) total_species_count,
               max(total_people_count) total_people_count,
               max(total_identifications_count) total_identifications_count
        FROM (
          SELECT
            count(*) as total_observations_count,
            CAST(NULL AS bigint) as total_species_count,
            CAST(NULL AS bigint) as total_people_count,
            sum(identifications_count) as total_identifications_count
          FROM
            "observations"
          WHERE
            observed_at < now()
        UNION
          SELECT
            CAST(NULL AS bigint) as total_observations_count,
            count(accepted_name) as total_species_count,
            CAST(NULL AS bigint) as total_people_count,
            CAST(NULL AS bigint) as total_identifications_count
          FROM (
            SELECT
              accepted_name
            FROM
              "observations"
            WHERE
              observed_at < now()
            GROUP BY
              accepted_name
          ) as t1
        UNION
          SELECT
            CAST(NULL AS bigint) as total_observations_count,
            CAST(NULL AS bigint) as total_species_count,
            count(creator_name) as total_people_count,
            CAST(NULL AS bigint) as total_identifications_count
          FROM (
            SELECT
              creator_name
            FROM
              "observations"
            WHERE
              observed_at < now()
            GROUP BY
              creator_name
          ) as t2
        UNION
          SELECT
            CAST(NULL AS bigint) as total_observations_count,
            CAST(NULL AS bigint) as total_species_count,
            CAST(NULL AS bigint) as total_people_count,
            sum(identifications_count) as total_identifications_count
          FROM
            "observations"
          WHERE
            observed_at < now()
        ) as final
      )
      WITH DATA
    SQL
    add_index :total_observations_metrics_matview, [:total_observations_count],
              name: 'total_observations_metrics_matview_unqique_idx', unique: true
  end
end
