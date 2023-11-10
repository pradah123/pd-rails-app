class CreateQuestaUserCivilSighting < ActiveRecord::Migration[7.0]
  def change
    create_table :questa_user_civil_sightings do |t|
      t.integer :user_id
      t.integer :observation_id
      t.belongs_to :observation_id, index: { unique: true }, foreign_key: true

      t.string :fullname
      t.string :profile_image_original
      t.string :profile_image_main
      t.string :profile_image_original
      t.string :exp_level
      t.string :civilization_color
      t.string :civilization_name
      t.string :civilization_profile_image
      t.string :disabled_at
      t.string :status
      t.boolean :locked
      t.float :locked_for_day 
      t.sting :locked_date
      t.string :locked_end_date
      t.boolean :correct_guess
      t.string :correct_ans
      t.string :difficulty_level
      t.timestamps
    end
  end
end
