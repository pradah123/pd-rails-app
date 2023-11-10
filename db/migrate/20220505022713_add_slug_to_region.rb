class AddSlugToRegion < ActiveRecord::Migration[6.1]
  def change
    add_column :regions, :slug, :string
  end
end
