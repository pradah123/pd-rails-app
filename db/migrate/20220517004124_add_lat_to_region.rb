class AddLatToRegion < ActiveRecord::Migration[6.1]
  def change
    add_column :regions, :lat, :float
  end
end
