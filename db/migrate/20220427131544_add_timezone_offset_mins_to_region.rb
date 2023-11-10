class AddTimezoneOffsetMinsToRegion < ActiveRecord::Migration[6.1]
  def change
    add_column :regions, :timezone_offset_mins, :integer, default: 0
  end
end
