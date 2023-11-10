class UpdateObserverSpeciesGroupedByDayMatview < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS observer_species_grouped_by_day_matview
    SQL
    execute <<-SQL
      CREATE MATERIALIZED VIEW observer_species_grouped_by_day_matview AS
      (
        SELECT t1.region_id, t1.scientific_name, t1.creator_name, t1.species_count, t1.observed_at, t2.common_name,
              t2.accepted_name, t2.image, t2.taxonomy_id, t2.canonical_name, t2.kingdom,
              t2.class_name, t2.phylum, t2.order, t2.family, t2.genus
          FROM 
        (
          SELECT                              
            obrs.region_id as region_id,
            obs.scientific_name as scientific_name,
            obs.creator_name as creator_name,
            obs.observed_at::date as observed_at,
            count(distinct obs.id) AS species_count    	
          FROM                                                
            observations_regions obrs
          INNER JOIN
            observations obs
          ON
            obrs.observation_id = obs.id
          GROUP BY
            obrs.region_id,
            obs.observed_at::date, 
            obs.scientific_name,
            obs.creator_name
        ) 
        as t1 LEFT JOIN 
        (
          SELECT  obrs.region_id as region_id,
            max(o.scientific_name) as scientific_name,
            max(o.common_name) as common_name,
            max(o.creator_name) as creator_name,
            max(o.accepted_name) as accepted_name, max(oi.url) as image,
            max(o.taxonomy_id) taxonomy_id,
            max(tax.canonical_name) as canonical_name, max(lower(tax.kingdom)) as kingdom,
            max(lower(class_name)) as class_name, max(lower(phylum)) as phylum,
            max(lower(tax.order)) as order, max(lower(family)) as family, max(lower(genus)) as genus
          FROM
            observations o
          INNER JOIN
            observations_regions obrs
          ON
            obrs.observation_id = o.id
          LEFT JOIN
            observation_images oi
          ON
            o.id = oi.observation_id
          LEFT JOIN
            taxonomies tax
          ON
            o.taxonomy_id = tax.id
          WHERE (
            o.license_code is null
            OR o.license_code IN ('cc-0', 'cc-by', 'cc-by-nc', 'cc-by-sa', 'cc-by-nd', 'cc-by-nc-sa', 'cc-by-nc-nd')
          )
          GROUP BY
            obrs.region_id,
            o.scientific_name,
            o.creator_name
        ) as t2 		
        ON t1.region_id    = t2.region_id AND 
        t1.scientific_name = t2.scientific_name AND
        t1.creator_name    = t2.creator_name
      )
      WITH DATA
    SQL
    add_index :observer_species_grouped_by_day_matview, :region_id, name: 'index_observer_species_grouped_by_day_region_id'
    add_index :observer_species_grouped_by_day_matview, :accepted_name, name: 'index_observer_species_grouped_by_day_on_accepted_name'
    add_index :observer_species_grouped_by_day_matview, :common_name, name: 'index_observer_species_grouped_by_day_on_common_name'
    add_index :observer_species_grouped_by_day_matview, :scientific_name, name: 'index_observer_species_grouped_by_day_on_scientific_name'
    add_index :observer_species_grouped_by_day_matview, :creator_name, name: 'idx_observer_species_grouped_by_day_on_creator_name'
    add_index :observer_species_grouped_by_day_matview, :image, name: 'index_observer_species_grouped_by_day_on_image'
    add_index :observer_species_grouped_by_day_matview, :species_count, name: 'index_observer_species_grouped_by_day_on_species_count'
    add_index :observer_species_grouped_by_day_matview, :taxonomy_id, name: 'index_observer_species_grouped_by_day_taxonomy_id'
    add_index :observer_species_grouped_by_day_matview, :kingdom, name: 'index_observer_species_grouped_by_day_kingdom'
    add_index :observer_species_grouped_by_day_matview, :class_name, name: 'index_observer_species_grouped_by_day_on_class_name'
    add_index :observer_species_grouped_by_day_matview, :phylum, name: 'index_observer_species_grouped_by_day_on_phylum'
    add_index :observer_species_grouped_by_day_matview, :order, name: 'index_observer_species_grouped_by_day_on_order'
    add_index :observer_species_grouped_by_day_matview, :family, name: 'index_observer_species_grouped_by_day_on_family'
    add_index :observer_species_grouped_by_day_matview, :genus, name: 'index_observer_species_grouped_by_day_on_genus'
    add_index :observer_species_grouped_by_day_matview, [:region_id, :scientific_name, :creator_name, :observed_at], unique: true, name: 'index_observer_species_grouped_by_day_on_p_id_s_name_c_name'
  end 
end
