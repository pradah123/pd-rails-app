class AddTypeToDataSource < ActiveRecord::Migration[7.0]
  def change
    add_column :data_sources, :type, :string
  end
end
