class UpdateSearchTextForObservations < ActiveRecord::Migration[6.1]
  def change
    Observation.all.each { |o| o.update_search_text }
  end
end
