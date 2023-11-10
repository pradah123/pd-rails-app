class ReReAddParameter < ActiveRecord::Migration[6.1]
  def change
    unless Region.column_names.include?('observation_dot_org_id')
      add_column :regions, :observation_dot_org_id, :integer 
    end
  end
end
