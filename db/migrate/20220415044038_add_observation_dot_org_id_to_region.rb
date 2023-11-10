class AddObservationDotOrgIdToRegion < ActiveRecord::Migration[6.1]
  def change
    add_column :regions, :observation_dot_org_id, :string
  end
end
