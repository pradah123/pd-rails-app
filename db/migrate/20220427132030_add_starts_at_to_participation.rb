class AddStartsAtToParticipation < ActiveRecord::Migration[6.1]
  def change
    add_column :participations, :starts_at, :datetime
  end
end
