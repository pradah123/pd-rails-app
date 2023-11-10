require_relative "../../common/transformer_functions.rb"

module Source
  class MushroomObserver
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations

      def self.populate_identifications_count(hash)
        identifications_count = hash[:votes]&.count || 0
        if identifications_count < 1 && hash[:scientific_name].present?
          identifications_count = 1
        end
        hash.merge({
          identifications_count: identifications_count
        })
      end

      def self.populate_images(hash)
        images = hash[:images] || [hash[:primary_image]] || []
        image_urls = images.present? ? images.map { |image| 
          image.present? ? image[:original_url] : '' } : []
        hash.merge({
          image_urls: image_urls
        })
      end

      def self.populate_lat_lng(hash)
        if !hash[:latitude].present? || !hash[:longitude].present?
          west  = hash.dig(:location, :longitude_west) || ''
          east  = hash.dig(:location, :longitude_east) || ''
          south = hash.dig(:location, :latitude_south) || ''
          north = hash.dig(:location, :latitude_north) || ''
          if (west.present? && east.present? && south.present? && north.present?)
            center = Utils.get_center_of_bounding_box(west, east, south, north)
            hash.merge({
              lat: center.lat,
              lng: center.lng
            })
          end
        else
          hash.merge({
            lat: hash[:latitude],
            lng: hash[:longitude]
          })
        end
      end
    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions
        
      define! do
        deep_symbolize_keys
        map_value :id, -> v { "mo-#{v}" }
        rename_keys id: :unique_id
        unwrap :consensus, [:name]
        rename_keys name: :scientific_name
        copy_keys scientific_name: :accepted_name
        unwrap :owner, [:legal_name, :id]
        map_value :id, -> v { v.to_s }
        rename_keys id: :creator_id
        rename_keys legal_name: :creator_name
        populate_images()
        populate_lat_lng()
        rename_keys date: :observed_at
        populate_identifications_count()
        accept_keys [
          :unique_id,
          :scientific_name,
          :common_name,
          :accepted_name,
          :creator_id,
          :creator_name,
          :image_urls,
          :lat,
          :lng,
          :observed_at,
          :identifications_count
        ]                
      end
    end    
  end
end
