class ResetAgainStatistics < ActiveRecord::Migration[6.1]
  def change
    Region.all.each { |r| r.reset_statistics }
    Participation.all.each { |p| p.reset_statistics }
    Contest.all.each { |c| c.reset_statistics }
  end
end
