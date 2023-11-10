class AddMaxRadiusKmToSubregion < ActiveRecord::Migration[6.1]
  def change
    unless Subregion.column_names.include?('max_radius_km')
      add_column :subregions, :max_radius_km, :float, default: 50.0
    end
  end
end
