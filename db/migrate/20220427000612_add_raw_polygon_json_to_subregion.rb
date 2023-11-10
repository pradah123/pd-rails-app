class AddRawPolygonJsonToSubregion < ActiveRecord::Migration[6.1]
  def change
    add_column :subregions, :raw_polygon_json, :text
  end
end
