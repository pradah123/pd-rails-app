class UpdateTimeFields < ActiveRecord::Migration[6.1]
  def change
    Region.reset_datetimes		
  end
end
