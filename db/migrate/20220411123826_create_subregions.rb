class CreateSubregions < ActiveRecord::Migration[6.1]
  def change
    create_table :subregions, force: :cascade do |t|
      t.string :params_json, default: '{}'
      t.references :region, null: false, foreign_key: {on_delete: :cascade}
      t.references :data_source, null: false, foreign_key: {on_delete: :cascade}
      t.timestamps
    end
  end
end
