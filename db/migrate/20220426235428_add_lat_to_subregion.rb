class AddLatToSubregion < ActiveRecord::Migration[6.1]
  def change
    add_column :subregions, :lat, :float
  end
end
