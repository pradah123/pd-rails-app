class ResetAllSlugs < ActiveRecord::Migration[7.0]
  def change
    Region.all.each { |r| r.set_slug }
    Contest.all.each { |c| c.set_slug }
  end
end
