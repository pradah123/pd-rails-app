class AddAddressToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :address, :string
  end
end
