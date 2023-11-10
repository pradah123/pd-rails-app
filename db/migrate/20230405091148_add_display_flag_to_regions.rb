class AddDisplayFlagToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :display_flag, :boolean, null: false, default: true
  end
end
