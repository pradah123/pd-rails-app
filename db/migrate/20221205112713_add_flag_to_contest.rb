class AddFlagToContest < ActiveRecord::Migration[7.0]
  def change
    add_column :contests, :fetch_neighboring_region_data, :boolean, default: false
  end
end
