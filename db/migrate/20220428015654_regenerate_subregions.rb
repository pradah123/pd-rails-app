class RegenerateSubregions < ActiveRecord::Migration[6.1]
  def change
    Subregion.all.destroy_all
    Region.all.each do |r|
      r.compute_subregions
    end
  end
end
