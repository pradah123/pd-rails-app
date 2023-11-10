class MoveImageUrlToImageModel < ActiveRecord::Migration[6.1]
  def change
    Observation.where.not(image_link: nil).each do |obs|
      ObservationImage.create! observation_id: obs.id, url: obs.image_link
    end
  end
end
