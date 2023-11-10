class AddCivilizationFieldsToObservations < ActiveRecord::Migration[7.0]
  def change
    add_column :observations, :civilization_name, :string
    add_column :observations, :civilization_id, :integer
    add_column :observations, :civilization_color, :string
    add_column :observations, :civilization_profile_pic, :string

    add_index :observations, :civilization_id
    add_index :observations, :civilization_name

  end
end
