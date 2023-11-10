class AddGoeFieldsToContests < ActiveRecord::Migration[7.0]
  def up
    add_column :contests, :goe_text, :string
    add_column :contests, :goe_url, :string
    add_column :contests, :logo_image_url, :string
    add_column :contests, :header_image_url, :string
  end
  def down
    remove_column :contests, :goe_text
    remove_column :contests, :goe_url
    remove_column :contests, :logo_image_url
    remove_column :contests, :header_image_url
  end

end
