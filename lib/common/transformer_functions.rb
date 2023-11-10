require_relative './utils.rb'

module TransformerFunctions
  extend Dry::Transformer::Registry
  import Dry::Transformer::ArrayTransformations
  import Dry::Transformer::HashTransformations

  def self.combine(hash, keys, to, separator=' ')
    components = keys.map{ |k| hash[k]}
    hash.merge(to => components.join(separator))
  end

  def self.add(hash, key, value)
    hash.merge(key => value)
  end

  def self.add_json(hash, key)
    hash.merge(key => hash.to_json)
  end

  def self.convert_to_utc(hash, lat_key, lng_key, date_key, time_key, new_key)
    hash.merge(
      new_key => Utils.get_utc_time(
        lat: hash[lat_key], 
        lng: hash[lng_key], 
        date_s: hash[date_key], 
        time_s: hash[time_key]
      )
    )            
  end
end
