class TotalObservationsMetricsMatview < ActiveRecord::Base
  self.table_name = 'total_observations_metrics_matview'

  def readonly?
    true
  end


  def self.get_total_observations_count
    return TotalObservationsMetricsMatview.first.total_observations_count.to_i
  end

  def self.get_total_species_count
    return TotalObservationsMetricsMatview.first.total_species_count.to_i
  end

  def self.get_total_people_count
    return TotalObservationsMetricsMatview.first.total_people_count.to_i
  end

  def self.get_total_identifications_count
    return TotalObservationsMetricsMatview.first.total_identifications_count.to_i
  end

  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY total_observations_metrics_matview')
  end
end
