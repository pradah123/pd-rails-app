class CreateMatviewForParticipationSpeciesByObserver < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS participation_observer_species_matview
    SQL
    execute <<-SQL
      CREATE MATERIALIZED VIEW participation_observer_species_matview AS
      (
        SELECT t1.participation_id, t1.scientific_name, t2.species_count, t1.common_name,
               t1.accepted_name, t1.creator_name, t1.image, t1.taxonomy_id, t1.canonical_name,
               t1.kingdom, t1.class_name, t1.phylum, t1.order, t1.family, t1.genus
        FROM
        (
          SELECT  obps.participation_id,
            max(o.scientific_name) as scientific_name,
            max(o.common_name) as common_name,
            o.creator_name as creator_name,
            max(o.accepted_name) accepted_name, max(oi.url) as image,
            max(o.taxonomy_id) taxonomy_id,
            max(tax.canonical_name) as canonical_name, max(lower(tax.kingdom)) as kingdom,
            max(lower(class_name)) as class_name, max(lower(phylum)) as phylum,
            max(lower(tax.order)) as order, max(lower(family)) as family, max(lower(genus)) as genus
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
          LEFT JOIN
            taxonomies tax
          ON
            o.taxonomy_id = tax.id
          GROUP BY
            obps.participation_id,
            o.scientific_name,
            o.creator_name
        ) t1 FULL OUTER JOIN
        (
          SELECT obps.participation_id,
                 obs.scientific_name,
                 obs.creator_name,
                 count(obs.scientific_name) AS species_count
          FROM
            observations_participations obps
          INNER JOIN
            observations obs
          ON
            obps.observation_id = obs.id
          GROUP BY
            obps.participation_id,
            obs.scientific_name,
            obs.creator_name
        ) t2
        ON t1.participation_id = t2.participation_id AND
           t1.scientific_name = t2.scientific_name   AND
           t1.creator_name = t2.creator_name
      )
      WITH DATA
    SQL
    add_index :participation_observer_species_matview, :participation_id, name: 'idx_participation_observer_species_matview_participation_id'
    add_index :participation_observer_species_matview, :accepted_name, name: 'idx_participation_observer_species_matview_on_accepted_name'
    add_index :participation_observer_species_matview, :common_name, name: 'idx_participation_observer_species_matview_on_common_name'
    add_index :participation_observer_species_matview, :scientific_name, name: 'idx_participation_observer_species_matview_on_scientific_name'
    add_index :participation_observer_species_matview, :creator_name, name: 'idx_participation_observer_species_matview_on_creator_name'
    add_index :participation_observer_species_matview, :image, name: 'idx_participation_observer_species_matview_on_image'
    add_index :participation_observer_species_matview, :species_count, name: 'idx_participation_observer_species_matview_on_species_count'
    add_index :participation_observer_species_matview, :taxonomy_id, name: 'idx_participation_observer_species_matview_taxonomy_id'
    add_index :participation_observer_species_matview, :kingdom, name: 'idx_participation_observer_species_matview_kingdom'
    add_index :participation_observer_species_matview, :class_name, name: 'idx_participation_observer_species_matview_on_class_name'
    add_index :participation_observer_species_matview, :phylum, name: 'idx_participation_observer_species_matview_on_phylum'
    add_index :participation_observer_species_matview, :order, name: 'idx_participation_observer_species_matview_on_order'
    add_index :participation_observer_species_matview, :family, name: 'idx_participation_observer_species_matview_on_family'
    add_index :participation_observer_species_matview, :genus, name: 'idx_participation_observer_species_matview_on_genus'
    add_index :participation_observer_species_matview, [:participation_id, :scientific_name, :creator_name], unique: true, name: 'idx_participation_observer_species_mv_on_p_id_s_name_c_name'
  end
  def down
    execute <<-SQL
      DROP VIEW IF EXISTS participation_observer_species_matview
    SQL
  end
end
