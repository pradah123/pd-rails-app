class AddCitsciProjectId < ActiveRecord::Migration[7.0]
  def change
      add_column :regions, :citsci_project_id, :string
  end
end
