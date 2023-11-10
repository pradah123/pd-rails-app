class AddExtraColumnsToTaxonomy < ActiveRecord::Migration[7.0]
  def change
    add_column :taxonomies, :order, :string
    add_column :taxonomies, :family, :string
    add_column :taxonomies, :genus, :string

    add_index :taxonomies, :order
    add_index :taxonomies, :family
    add_index :taxonomies, :genus
  end
end
