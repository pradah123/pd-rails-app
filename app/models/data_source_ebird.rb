class DataSourceEbird < DataSourceNew
  
  def fetch
    params = {
      lat: subregion.lat,
      lng: subregion.lng,
      dist: subregion.radius_km.ceil,
      sort: "date"#,
      #back: ((Time.now - starts_at).to_i / (24 * 60 * 60) ) 
    }

    observations = []

    begin
  #    ebird = ::Source::Ebird.new **params
  #    observations = bird.get_observations() || []
    rescue => e
      Rails.logger.error "fetch_observations_dot_org: #{e.full_message}"
    end

    observations
  end

end
