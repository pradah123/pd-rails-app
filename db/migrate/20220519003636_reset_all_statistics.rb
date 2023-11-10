class ResetAllStatistics < ActiveRecord::Migration[7.0]
  def change
    Region.all.each { |r| r.reset_statistics }
    Participation.all.each { |r| r.reset_statistics }
    Contest.all.each { |r| r.reset_statistics }
  end
end
