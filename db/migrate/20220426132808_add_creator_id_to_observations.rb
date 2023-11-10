class AddCreatorIdToObservations < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :creator_id, :string, index: true
  end
end
