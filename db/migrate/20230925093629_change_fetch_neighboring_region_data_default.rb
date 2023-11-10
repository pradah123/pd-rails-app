class ChangeFetchNeighboringRegionDataDefault < ActiveRecord::Migration[7.0]
  def up
    change_column_default :contests, :fetch_neighboring_region_data, true
  end
  def down
    change_column_default :contests, :fetch_neighboring_region_data, false
  end
end
