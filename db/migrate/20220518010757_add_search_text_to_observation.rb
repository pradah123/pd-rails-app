class AddSearchTextToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :search_text, :text
    remove_column :observations, :image_link, :string
  end
end
