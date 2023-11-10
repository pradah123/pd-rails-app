class CreateSpeciesByRegionsMatview < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS species_by_regions_matview
    SQL
    execute <<-SQL
      CREATE MATERIALIZED VIEW species_by_regions_matview AS
      (
        SELECT
          distinct obrs.region_id as region_id,
          obs.*
        FROM
          observations_regions obrs
        INNER JOIN
          observations obs
        ON
          obrs.observation_id = obs.id
        INNER JOIN
          taxonomies as taxon
        ON
          taxon.id  = obs.taxonomy_id
        WHERE
          taxon.taxon_rank IN ('species', 'subspecies')
      )
      WITH DATA
    SQL
    add_index :species_by_regions_matview, :region_id, name: 'index_species_by_regions_matview_on_region_id'
    add_index :species_by_regions_matview, :scientific_name, name: 'index_species_by_regions_matview_on_scientific_name'
    add_index :species_by_regions_matview, :accepted_name, name: 'index_species_by_regions_matview_on_accepted_name'
    add_index :species_by_regions_matview, :common_name, name: 'index_species_by_regions_matview_on_common_name'
    add_index :species_by_regions_matview, :taxonomy_id, name: 'index_species_by_regions_matview_on_taxonomy_id'
    add_index :species_by_regions_matview, :observed_at, name: 'index_species_by_regions_matview_on_observed_at'
    add_index :species_by_regions_matview, [:id, :region_id], unique: true
  end
end
