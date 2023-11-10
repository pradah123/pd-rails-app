class CreateParams < ActiveRecord::Migration[7.0]
  def change
    create_table :params do |t|
      t.references :contest, foreign_key: true
      t.references :data_source, foreign_key: true
      t.string :name, null: false
      t.string :value , null: false
      t.timestamps
    end
  end
end
