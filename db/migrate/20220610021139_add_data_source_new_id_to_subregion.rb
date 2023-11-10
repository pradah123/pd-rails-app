class AddDataSourceNewIdToSubregion < ActiveRecord::Migration[7.0]
  def change
    add_column :subregions, :data_source_new_id, :integer
  end
end
