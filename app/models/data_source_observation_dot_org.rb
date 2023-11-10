class DataSourceObservationDotOrg < DataSourceNew

  def fetch
    return if subregion.region.observation_dot_org_id.nil?
      
    params = {
      location_id: (subregion.region.observation_dot_org_id), 
      offset: 0, 
      limit: 100#,
      #date_after: starts_at.strftime('%F')
      #date_before: ends_at.strftime('%F')
    }
     
    observations = [] 
 
    begin  
#      ob_org = ::Source::ObservationOrg.new(**params)
#      loop do                
#        observations.push (ob_org.get_observations() || [])
#        break if ob_org.done()
#        ob_org.increment_offset()
#      end
    rescue => e
      Rails.logger.error "fetch_observations_dot_org: #{e.full_message}"      
    end      

    observations
  end  
  
end
