class AddAreaToContests < ActiveRecord::Migration[7.0]
  def up
    add_column :contests, :total_area, :float, default: 0.0
  end
  def down
    remove_column :contests, :total_area
  end
end
