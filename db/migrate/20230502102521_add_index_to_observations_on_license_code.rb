class AddIndexToObservationsOnLicenseCode < ActiveRecord::Migration[7.0]
  def change
    add_index :observations, :license_code
  end
end
