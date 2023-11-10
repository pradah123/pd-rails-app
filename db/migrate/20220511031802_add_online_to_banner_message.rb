class AddOnlineToBannerMessage < ActiveRecord::Migration[6.1]
  def change
    add_column :banner_messages, :online, :boolean, default: true
  end
end
