class CreateViewForParticipationObservationsWithImages < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE VIEW participation_observations_view AS
      SELECT  observations.*, obps.participation_id, oi.url
        FROM
          observations
        INNER JOIN
          observations_participations obps
        ON
          obps.observation_id = observations.id
        LEFT JOIN
          observation_images oi
        ON
          observations.id = oi.observation_id
    SQL
  end
  def down
    execute <<-SQL
      DROP VIEW IF EXISTS participation_observations_view
    SQL
  end
end
