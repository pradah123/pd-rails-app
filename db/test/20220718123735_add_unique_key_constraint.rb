class AddUniqueKeyConstraint < ActiveRecord::Migration[6.1]
    def change
      Contest.all.each do |c|
        c.observations.group(:observation_id).values.each do |dup|
        dup.pop #leave one
        dup.each(&:destroy) #destroy remaining
      end
      Region.all.each do |r|
        r.observations.group(:observation_id).values.each do |dup|
        dup.pop #leave one
        dup.each(&:destroy) #destroy remaining
      end
      Participation.all.each do |p|
        p.observations.group(:observation_id).values.each do |dup|
        dup.pop #leave one
        dup.each(&:destroy) #destroy remaining
      end
      
      add_index :contests_observations, [:contest_id, :observation_id], unique: true
      add_index :observations_regions, [:region_id, :observation_id], unique: true
      add_index :observations_participations, [:participation_id, :observation_id], unique: true
     end
  end