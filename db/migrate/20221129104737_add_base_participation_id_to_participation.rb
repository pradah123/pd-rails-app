class AddBaseParticipationIdToParticipation < ActiveRecord::Migration[7.0]
  def change
    add_column :participations, :base_participation_id, :integer
    add_index :participations, :base_participation_id
  end
end
