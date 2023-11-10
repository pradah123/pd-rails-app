class AddLastSubmissionAcceptedAtToParticipation < ActiveRecord::Migration[6.1]
  def change
    add_column :participations, :last_submission_accepted_at, :datetime
  end
end
