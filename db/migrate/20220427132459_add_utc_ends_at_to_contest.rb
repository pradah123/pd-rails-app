class AddUtcEndsAtToContest < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :utc_ends_at, :datetime
  end
end
