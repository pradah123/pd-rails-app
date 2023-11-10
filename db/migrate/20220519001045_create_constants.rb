class CreateConstants < ActiveRecord::Migration[7.0]
  def change
    create_table :constants do |t|
      t.string :name
      t.float :value, default: 0.0
      t.timestamps
    end
  end
end
