class AddApiHashToConstants < ActiveRecord::Migration[7.0]
  def change
    add_column :constants, :text_value, :string
    Constant.create! name: 'api_hash', value: nil, text_value: "c3ab8ff13720e8ad9047dd39466b3c8974e592c2fa383d4a3960714caef0c4f2"
  end
end
