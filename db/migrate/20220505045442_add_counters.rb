class AddCounters < ActiveRecord::Migration[6.1]
  def change
    remove_column :contests, :sightings_count, :integer, default: 0
    remove_column :contests, :participants_count, :integer, default: 0
    remove_column :regions, :sightings_count, :integer, default: 0
    remove_column :regions, :participants_count, :integer, default: 0
    remove_column :participations, :sightings_count, :integer, default: 0
    remove_column :participations, :participants_count, :integer, default: 0

    add_column :contests, :observations_count, :integer, default: 0
    add_column :contests, :people_count, :integer, default: 0
    add_column :regions, :observations_count, :integer, default: 0
    add_column :regions, :people_count, :integer, default: 0
    add_column :participations, :observations_count, :integer, default: 0
    add_column :participations, :people_count, :integer, default: 0
  end
end
