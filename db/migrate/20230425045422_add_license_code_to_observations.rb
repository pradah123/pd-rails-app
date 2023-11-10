class AddLicenseCodeToObservations < ActiveRecord::Migration[7.0]
  def change
    add_column :observations, :license_code, :string
  end
end
