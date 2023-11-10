class AddEndsAtToParticipation < ActiveRecord::Migration[6.1]
  def change
    add_column :participations, :ends_at, :datetime
  end
end
