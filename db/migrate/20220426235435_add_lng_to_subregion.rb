class AddLngToSubregion < ActiveRecord::Migration[6.1]
  def change
    add_column :subregions, :lng, :float
  end
end
