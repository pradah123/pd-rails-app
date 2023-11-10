class DataSourceQuestagame < DataSourceNew

  def fetch
    multipolygon_wkt = Region.get_multipolygon_from_raw_polygon_json raw_polygon_json
 
    params = {
      multipolygon: multipolygon_wkt, 
      offset: 0, 
      limit: 50#,
      #start_dttm: starts_at.strftime('%F')
      #end_dttm: ends_at.strftime('%F')
    }

    observations = []

    begin
#      qgame = ::Source::QGame.new(**params)    
#      loop do      
#        break if qgame.done()
#        observations.push(qgame.get_observations() || [])       
#        qgame.increment_offset()
#      end
    rescue => e
      Rails.logger.error "fetch_observations_dot_org: #{e.full_message}"
    end      

    observations
  end  
  
end
