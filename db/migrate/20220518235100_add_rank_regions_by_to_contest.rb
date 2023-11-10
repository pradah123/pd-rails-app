class AddRankRegionsByToContest < ActiveRecord::Migration[7.0]
  def change
    add_column :contests, :rank_regions_by, :integer, default: 0
  end
end
