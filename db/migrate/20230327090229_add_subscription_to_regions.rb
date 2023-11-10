class AddSubscriptionToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :subscription, :string, default: 'seeded'
  end
end
