class AddBioscoreToRegion < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :bioscore, :float, default: 0.0
    add_column :participations, :bioscore, :float, default: 0.0
    add_column :contests, :bioscore, :float, default: 0.0
  end
end
