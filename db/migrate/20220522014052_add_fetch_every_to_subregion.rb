class AddFetchEveryToSubregion < ActiveRecord::Migration[7.0]
  def change
    add_column :subregions, :fetch_every, :integer, default: 0
  end
end
