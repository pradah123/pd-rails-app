class RefreshSubregions < ActiveRecord::Migration[6.1]
  def change
    Region.all.each do |r|
      r.compute_subregions
    end
  end
end
