class AddBioscoreAgainToRegion < ActiveRecord::Migration[7.0]
  def change
    change_column :regions, :bioscore, :float, default: 0.0
    add_column :participations, :bioscore, :float, default: 0.0
    add_column :contests, :bioscore, :float, default: 0.0
    Region.where(bioscore: nil).each { |r| r.update! bioscore: 0.0 }
  end
end
