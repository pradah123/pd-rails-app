class AddDefaultToScientificName < ActiveRecord::Migration[6.1]
  def change
    change_column :observations, :scientific_name, :string, default: 'TBD'
  end
end
