class CreateBannerMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :banner_messages do |t|
      t.string :message
      t.string :background_colour, default: '#dc3545'
      t.string :text_colour, default: '#ffffff'
      t.timestamps
    end
  end
end
