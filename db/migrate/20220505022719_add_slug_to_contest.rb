class AddSlugToContest < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :slug, :string
  end
end
