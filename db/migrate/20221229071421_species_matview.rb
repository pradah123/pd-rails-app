class SpeciesMatview < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS species_matview
    SQL
    execute <<-SQL
      CREATE MATERIALIZED VIEW species_matview AS
      (
        SELECT
          DISTINCT observations.scientific_name as species_name
        FROM
          observations
        INNER JOIN
          taxonomies
        ON
          taxonomies.id = observations.taxonomy_id
        WHERE (taxonomies.taxon_rank IN ('species', 'subspecies'))
        UNION
        SELECT
          DISTINCT observations.common_name as species_name
        FROM
          observations
        INNER JOIN
          taxonomies
        ON
          taxonomies.id = observations.taxonomy_id
        WHERE (taxonomies.taxon_rank IN ('species', 'subspecies'))
      )
      WITH DATA
    SQL
    add_index :species_matview, :species_name, unique: true, name: 'index_species_matview_on_species_name'
  end
end
