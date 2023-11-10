class CreateTaxonomy < ActiveRecord::Migration[7.0]
  def change
    create_table :taxonomies do |t|
      t.string :taxon_id, null: false
      t.string :source, null: false
      t.string :scientific_name
      t.string :canonical_name
      t.string :accepted_name
      t.string :generic_name
      t.string :accepted_name_usage_id
      t.string :kingdom
      t.string :phylum
      t.string :class_name
      t.string :taxonomic_status
      t.string :taxon_rank
      t.timestamps
    end
    add_reference :observations, :taxonomy, index: true, foreign_key: { to_table: :taxonomies }
    add_index :taxonomies, :taxon_id
    add_index :taxonomies, :accepted_name_usage_id
    add_index :taxonomies, [:taxon_id, :source], unique: true, name: 'taxon_id_source_ukey'
  end
end
