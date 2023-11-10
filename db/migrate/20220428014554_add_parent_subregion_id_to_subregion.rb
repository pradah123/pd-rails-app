class AddParentSubregionIdToSubregion < ActiveRecord::Migration[6.1]
  def change
    add_column :subregions, :parent_subregion_id, :integer
  end
end
