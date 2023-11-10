class RemoveNullConstraint < ActiveRecord::Migration[6.1]
  def change
    change_column :subregions, :region_id, :integer, :null => true
    change_column :subregions, :data_source_id, :integer, :null => true
  end
end
