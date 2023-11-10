require_relative '../source/inaturalist.rb'

module Sightings
  def self.file_name
    return "#{Rails.root}/lib/sightings/.to_date.txt"
  end

  def self.update_inaturalist_sightings(from_date, to_date, days)
    from_date = from_date.to_time if from_date.present?
    to_date = to_date.to_time if to_date.present?

    file = File.open(file_name, "r") if File.file?(file_name)
    file_to_date = file.read if file.present?
    file.close()
    unless from_date.present?
      to_date = file_to_date.present? ? file_to_date.to_time : Time.now.utc
      from_date = to_date - Utils.convert_to_seconds(unit: 'days', value: days.to_i)
    end
    # data_source_id = DataSource.where(name: ["inaturalist", "gbif"]).pluck(:id)
    data_source_id = DataSource.find_by_name("inaturalist")

    unique_ids = Observation.where("observed_at BETWEEN ? and ?", from_date, to_date)
                            .where(data_source_id: data_source_id)
                            .where(license_code: nil)
                            #.ignore_reserved_sightings
                            .order("observed_at desc")
                            .pluck(:unique_id)
    Rails.logger.info("Sightings::update_inaturalist_sightings - No. of observations to be fetched from #{from_date} - to #{to_date}: #{unique_ids.count}")

    unique_ids.each do |unique_id|
      id = unique_id.gsub('inaturalist-', '')
      Rails.logger.info("Sightings::update_inaturalist_sightings - Fetching observation for id: #{id}")
      attributes = fetch_sighting_from_inaturalist(from_date, to_date, id)
      next unless attributes.present?

      obs = Observation.find_by_unique_id unique_id
      obs.attributes = attributes
      
      begin
        obs.save unless obs.changed.empty?
        observed_at = obs.observed_at.to_s
        file = File.open(file_name, "w") if File.file?(file_name)
        file.write(observed_at)
        file.close()
      rescue => e
        Rails.logger.info("Sightings::update_inaturalist_sightings - Failed to update inaturalist license code for sighting #{unique_id}, #{e}")
      end

      sleep(30)
    end
    Rails.logger.info("Sightings::update_inaturalist_sightings - Finished processing.")
  end

  def self.fetch_sighting_from_inaturalist(from_date, to_date, id)
    params = { 
      d1: from_date.strftime('%Y-%m-%d'),
      d2: to_date.strftime('%Y-%m-%d'),
      lat: -36.90512555988591, # Any lat, just to satisfy ::Source::Inaturalist structure
      lng: 174.5181026210274, # Any lng, just to satisfy ::Source::Inaturalist structure
      radius: 59, # Any radius, just to satisfy ::Source::Inaturalist structure
      id: id
    }
    inaturalist = ::Source::Inaturalist.new(**params)
    attributes = inaturalist.get_observations()
    attributes = attributes[0]
    attributes.delete :image_urls if attributes.present?
    return attributes
  end

  def self.generate_questa_civilizations_json
    url = Addressable::URI.parse("https://api.questagame.com/api/civilization_details").display_uri.to_s
    response = HTTParty.get(url)
    result = JSON.parse(response.body)
    File.open("#{Rails.root}/lib/sightings/questa_civilizations.json", 'w') do |f|
      f.write(result["data"].to_json)
    end
  end

  def self.fetch_questa_civilizations
    file_name = "#{Rails.root}/lib/sightings/questa_civilizations.json"
    generate_questa_civilizations_json() unless File.file?(file_name)
    file = File.open file_name
    civilizations = JSON.load file
  end


  def self.get_random_civilization(civilizations: nil)
    civilizations = fetch_questa_civilizations() unless civilizations.present?
    civilizations_hash = Hash[civilizations.map { |r| [r["id"], r] }]
    key = civilizations_hash.keys.sample
    return civilizations_hash[key]
  end


  def self.update_civilization_for_old_sightings(days)
    file_name = "#{Rails.root}/lib/sightings/.old_sightings_civilization_update_last_date.txt"
    if File.file?(file_name)
      file = File.open(file_name, "r")
      file_to_date = file.read if file.present?
      file.close()
    end
    to_date = file_to_date.present? ? file_to_date.to_time : Time.now.utc
    from_date = to_date - Utils.convert_to_seconds(unit: 'days', value: days.to_i)
    civilizations = fetch_questa_civilizations
    data_source_id = DataSource.find_by_name("qgame")

    observation_ids = Observation.where("observed_at BETWEEN ? and ?", from_date, to_date)
                                 .where.not(data_source_id: data_source_id)
                                 .where(civilization_id: nil).pluck(:id)
    Rails.logger.info("Sightings::update_civilization_for_old_sightings - No. of observations to be updated from #{from_date} - to #{to_date}: #{observation_ids.length}")

    observation_ids.each do |obs_id|
      random_civilization = get_random_civilization(civilizations: civilizations)

      begin
        obs = Observation.find_by_id(obs_id)
        update_status = obs.update(civilization_id: random_civilization["id"],
                                   civilization_name: random_civilization["name"],
                                   civilization_color: random_civilization["color"],
                                   civilization_profile_pic: random_civilization["profile_pic"] )
        if update_status
          observed_at = obs.observed_at.to_s
          file = File.open(file_name, "w")
          file.write(observed_at)
          file.close()
        end
      rescue => e
        Rails.logger.info("Sightings::update_civilization_for_old_sightings - Failed to update inaturalist license code for sighting #{unique_id}, #{e}")
      end
    end
    Rails.logger.info("Sightings::update_civilization_for_old_sightings - Finished processing.")
  end
end
