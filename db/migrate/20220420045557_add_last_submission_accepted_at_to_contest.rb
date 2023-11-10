class AddLastSubmissionAcceptedAtToContest < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :last_submission_accepted_at, :datetime
  end
end
