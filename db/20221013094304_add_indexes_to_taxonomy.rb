class AddIndexesToTaxonomy < ActiveRecord::Migration[7.0]
  def change
    add_index :taxonomies, :kingdom
    add_index :taxonomies, :phylum
    add_index :taxonomies, :class_name
  end
end
