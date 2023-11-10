require_relative '../source/inaturalist.rb'

module OldSightings
  def self.file_name
    return "#{Rails.root}/lib/sightings/.old_sightings_to_date"
  end

  def self.update_inaturalist_sightings(from_date, to_date, days)
    from_date = from_date.to_time if from_date.present?
    to_date = to_date.to_time if to_date.present?

    regions_hash = load(file_name)

    # file = File.open(file_name, "r") if File.file?(file_name)
    # file_to_date = file.read if file.present?
    # file.close()

    regions = get_regions()
    regions.each do |region|
      # Rails.logger.info("Sightings::update_inaturalist_sightings for region : #{region.name} - #{region.id}")
      data_source_id = DataSource.find_by_name("inaturalist")

      subregions = Subregion.where(region_id: region.id, data_source_id: data_source_id)
      subregions.each do |subregion|
        file_data = load(file_name)
        # Rails.logger.info("file_data: #{file_data}")
        if !from_date.present? && days.present?
          if file_data.key?(subregion.id.to_s)
            end_dt = file_data[subregion.id.to_s].to_time 
            end_dt -= Utils.convert_to_seconds(unit: 'days', value: 1)
          else
            end_dt = Time.now.utc
          end
          start_dt = end_dt - Utils.convert_to_seconds(unit: 'days', value: days.to_i)
        elsif from_date.present? && to_date.present?
          end_dt = to_date
          start_dt = from_date
        else
          Rails.logger.info("Sightings::update_inaturalist_sightings dates are not given correctly")
        end
        observations_count = Region.find_by_id(region.id).observations.where("observed_at between ? and ?", start_dt, end_dt).count
        next unless observations_count.positive?
        Rails.logger.info("subregion: #{subregion.id}, start_dt: #{start_dt}, end_dt: #{end_dt}")
        Rails.logger.info("observations_count : #{observations_count}")
        # exit(0)

        observations = fetch_inat_sightings subregion, start_dt, end_dt
        observations.each do |obs|
          if subregion.region.contains? obs[:lat], obs[:lng]
            observed_at = update_observation(obs, subregion.id)
            if file_data.key?(subregion.id.to_s.to_sym) && 
               observed_at.present? &&
               file_data[subregion.id.to_s.to_sym].to_time > observed_at
              file_data[subregion.id.to_s.to_sym] = observed_at
            elsif !file_data.key?(subregion.id.to_s.to_sym) && observed_at.present?
              file_data[subregion.id.to_s.to_sym] = observed_at
            end
          end
        end
        save(file_name, file_data)
        sleep(5)
      end
    end
    # unique_ids = Observation.where("observed_at BETWEEN ? and ?", from_date, to_date)
    #                         .where(data_source_id: data_source_id)
    #                         .ignore_reserved_sightings
    #                         .order("observed_at desc")
    #                         .pluck(:unique_id)
    # Rails.logger.info("Sightings::filter_inaturalist_sightings no. of observations to be fetched from #{from_date} - to #{to_date}: #{unique_ids.count}")

    # unique_ids.each do |unique_id|
    #   id = unique_id.gsub('inaturalist-', '')
    #   Rails.logger.info("Fetching observation for id: #{id}")
    #   attributes = fetch_sighting_from_inaturalist(from_date, to_date, id)
    #   next unless attributes.present?

    #   obs = Observation.find_by_unique_id unique_id
    #   obs.attributes = attributes
      
    #   begin
    #     obs.save unless obs.changed.empty?
    #     observed_at = obs.observed_at.to_s
    #     file = File.open(file_name, "w") if File.file?(file_name)
    #     file.write(observed_at)
    #     file.close()
    #   rescue => e
    #     Rails.logger.info("Failed to update inaturalist license code for sighting #{unique_id}, #{e}")
    #   end

    #   sleep(1)
    # end
  end

  def self.get_regions
    regions = []
    Region.all.each do |r|
      next if r.base_region_id.present?
      nr = r.get_neighboring_region(region_type: 'greater_region')
      if nr.present?
          regions.push(nr)
      else
        regions.push(r)
      end
    end
  end


  def self.fetch_inat_sightings(subregion, from_date, to_date)
    observations = []
    # fetch logic here
    Rails.logger.info "Sightings::fetch_inat_sightings(#{subregion.id}, #{from_date}, #{to_date})"
    begin
      params = get_inaturalist_params(subregion, from_date, to_date)

      inat = ::Source::Inaturalist.new(**params)
      observations = inat.get_observations() || []
    rescue => e
      Rails.logger.info "Sightings::fetch_inat_sightings: #{e.full_message}"
    end
    return observations
  end 

  def self.get_inaturalist_params(subregion, from_date, to_date)
    params = {
      d1: from_date.strftime('%Y-%m-%d'),
      d2: to_date.strftime('%Y-%m-%d'),
      lat: subregion.lat,
      lng: subregion.lng,
      radius: subregion.radius_km.ceil,
      geo: true,
      order: "desc",
      order_by: "observed_on",
      per_page: 200,
      page: 1
    }
    return params
  end


  def self.update_observation(params, subregion_id)
    # puts(params)
    obs = Observation.find_by_unique_id params[:unique_id]
    return unless obs.present?
    image_urls = (params.delete :image_urls) || []
    obs.attributes = params
      
    begin
      obs.save unless obs.changed.empty?
      observed_at = obs.observed_at.to_time
      # return unless observed_at.present?
      # file = File.open(file_name, "r") if File.file?(file_name)
      # file_to_date = file.read || '' if file.present?
      # file.close()
      # puts("observed_at: #{observed_at}, file_to_date: #{file_to_date}")
      # if (observed_at.present? && file_to_date.blank?) || 
      #    (observed_at.present? && 
      #     file_to_date.present? &&
      #     observed_at < file_to_date.to_time)

      #   file = File.open(file_name, "w") if File.file?(file_name)
      #   file.write(observed_at)
      #   file.close()
      # end
      return observed_at
    rescue => e
      Rails.logger.info("Sightings::update_observation - Failed to update inaturalist license code for sighting #{unique_id}, #{e}")
    end
  end

  def self.load(file_name)
    data = nil
    File.open(file_name) do |f|
      data = JSON.parse(f.read)
      close(f)
    end
    return data
  end

  def self.close(file_handle)
    file_handle.close()
  end

  def self.save(file_name, data)
    File.open(file_name, "w") do |f|
      f.write(data.to_json)
      close(f)
    end
  end
  
  def self.process(file_name, subregion_id, observed_at)
    catalogue = load(file_name)
  
    p catalogue
  
    catalogue[subregion_id.to_sym] = observed_at
    save(file_name, catalogue)
  end

  
  # def fetch_sighting_from_inaturalist(from_date, to_date, id)
  #   params = { 
  #     d1: from_date.strftime('%Y-%m-%d'),
  #     d2: to_date.strftime('%Y-%m-%d'),
  #     lat: -36.90512555988591, # Any lat, just to satisfy ::Source::Inaturalist structure
  #     lng: 174.5181026210274, # Any lng, just to satisfy ::Source::Inaturalist structure
  #     radius: 59, # Any radius, just to satisfy ::Source::Inaturalist structure
  #     id: id
  #   }
  #   inaturalist = ::Source::Inaturalist.new(**params)
  #   attributes = inaturalist.get_observations()
  #   attributes = attributes[0]
  #   attributes.delete :image_urls if attributes.present?
  #   return attributes
  # end
end

