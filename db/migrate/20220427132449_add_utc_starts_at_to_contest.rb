class AddUtcStartsAtToContest < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :utc_starts_at, :datetime
  end
end
