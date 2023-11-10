class DataSourceInaturalist < DataSourceNew

  def fetch
    params = {
      lat: subregion.lat,
      lng: subregion.lng,
      radius: subregion.radius_km.ceil,
      geo: true,
      order: "desc",
      order_by: "observed_on",
      per_page: 200,
      page: 1#,
      #d1: starts_at.strftime('%F'),
      #d2: ends_at.strftime('%F'), 
    }

    observations = []

    begin
#      inat = ::Source::Inaturalist.new **params
#      loop do
#        break if inat.done()
#        observations.push (inat.get_observations() || [])
#        inat.increment_page()
#      end
    rescue => e
      Rails.logger.error "inaturalist: #{e.full_message}"
    end

    observations
  end  
  
end
