class AddLngToRegion < ActiveRecord::Migration[6.1]
  def change
    add_column :regions, :lng, :float
  end
end
