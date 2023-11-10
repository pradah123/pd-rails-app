class AddLastSubmissionAcceptedAtToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :last_submission_accepted_at, :datetime
  end
end
