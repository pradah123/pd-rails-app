class AddObservationImagesCountToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :observation_images_count, :integer, default: 0
  end
end
