class AddDefaultForRegion < ActiveRecord::Migration[7.0]
  def change
    change_column :regions, :raw_polygon_json, :string, default: '[]'
  end
end
