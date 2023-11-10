class CreateMatviewForParticipationObservationsWithImages < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW participation_observations_matview AS
      ( 
        SELECT  obps.participation_id,
                max(o.scientific_name) as scientific_name,
                max(o.common_name) as common_name,
                max(o.accepted_name) accepted_name, max(oi.url) as url
        FROM
          observations o
        INNER JOIN
          observations_participations obps
        ON
          obps.observation_id = o.id
        LEFT JOIN
          observation_images oi
        ON
          o.id = oi.observation_id
        GROUP BY
        obps.participation_id,
        o.scientific_name
      )
      WITH DATA
    SQL
    add_index :participation_observations_matview, :participation_id, name: 'index_participation_observations_matview_on_participation_idd'
    add_index :participation_observations_matview, :accepted_name, name: 'index_participation_observations_matview_on_accepted_name'
    add_index :participation_observations_matview, :common_name, name: 'index_participation_observations_matview_on_common_name'
    add_index :participation_observations_matview, :scientific_name, name: 'index_participation_observations_matview_on_scientific_name'
    add_index :participation_observations_matview, :url, name: 'index_participation_observations_matview_on_url'

  end
  def down
    execute <<-SQL
      DROP VIEW IF EXISTS participation_observations_matview
    SQL
  end
end
