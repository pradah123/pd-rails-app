class AddIndexesToObservationsAndTaxonomy < ActiveRecord::Migration[7.0]
  def change
    add_index :observations, :scientific_name
    add_index :taxonomies, :scientific_name
    add_index :taxonomies, :canonical_name
  end
end
