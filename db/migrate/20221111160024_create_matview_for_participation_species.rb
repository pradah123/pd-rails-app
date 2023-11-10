class CreateMatviewForParticipationSpecies < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW participation_species_matview AS
      ( 
        SELECT t1.participation_id,
               t1.scientific_name,
               t2.species_count,
               t1.common_name,
               t1.accepted_name,
               t1.image
        FROM 
        (
          SELECT  obps.participation_id,
              max(o.scientific_name) as scientific_name,
              max(o.common_name) as common_name,
              max(o.accepted_name) accepted_name, max(oi.url) as image
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
        ) t1 FULL OUTER JOIN
        (SELECT obps.participation_id,
                obs.scientific_name,
                count(obs.scientific_name) AS species_count
          FROM
              observations_participations obps
          INNER JOIN
              observations obs
          ON
              obps.observation_id = obs.id
          GROUP BY
              obps.participation_id,
              obs.scientific_name
        ) t2
        ON t1.participation_id = t2.participation_id AND t1.scientific_name = t2.scientific_name
      )
      WITH DATA
    SQL
    add_index :participation_species_matview, :participation_id, name: 'index_participation_species_matview_participation_id'
    add_index :participation_species_matview, :accepted_name, name: 'index_participation_species_matview_on_accepted_name'
    add_index :participation_species_matview, :common_name, name: 'index_participation_species_matview_on_common_name'
    add_index :participation_species_matview, :scientific_name, name: 'index_participation_species_matview_on_scientific_name'
    add_index :participation_species_matview, :image, name: 'index_participation_species_matview_on_image'
    add_index :participation_species_matview, :species_count, name: 'index_participation_species_matview_on_species_count'
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS participation_species_matview
    SQL
  end
end
