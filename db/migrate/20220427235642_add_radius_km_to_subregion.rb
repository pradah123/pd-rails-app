class AddRadiusKmToSubregion < ActiveRecord::Migration[6.1]
  def change
    unless Subregion.column_names.include?('radius_km')
      add_column :subregions, :radius_km, :float, default: 0.0
    end
  end
end
