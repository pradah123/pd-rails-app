class CreateObservationImages < ActiveRecord::Migration[6.1]
  def change
    create_table :observation_images do |t|
      t.integer :observation_id
      t.string :url
      t.string :url_thumbnail
      t.string :license_code
      t.string :attribution

      t.timestamps
    end
  end
end
