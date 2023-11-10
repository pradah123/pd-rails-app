class AddIndexToObservationImages < ActiveRecord::Migration[7.0]
  def change
    add_index :observation_images, :observation_id
  end
end
