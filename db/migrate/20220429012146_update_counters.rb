class UpdateCounters < ActiveRecord::Migration[6.1]
  def change
    Observation.all.each do |o|
      Observation.reset_counters o.id, :observation_images
    end
  end
end
