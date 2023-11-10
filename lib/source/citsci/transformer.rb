require_relative "../../common/transformer_functions.rb"

module Source
  class CitSci
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations
    
      ## We need to fetch ids which later are used to fetch scientific name
      def self.populate_unique_id(hash)
        records = hash[:records]
        unique_id = ''
        observation_url = ''
        records.each do |record| 
          if record[:recordType] == 'organism'
            unique_id = "citsci-#{record[:id]}"
            observation_url = record[:"@id"]
          end
        end
        unique_id = "citsci-#{hash[:id]}" if unique_id.blank?

        hash.merge({
          unique_id: unique_id,
          observation_url: observation_url
        })
      end

      def self.populate_images(hash)
        records = hash[:records]
        image_url = []

        records.each do |record|
          if record[:recordType] == 'image'
            image_url.push(record.dig(:fileObject, :path))
          end
        end
        hash.merge({
          image_urls: image_url
        })
      end

      def self.populate_identifications_count(hash)
        records = hash[:records]
        identifications_count = 0
        records.each do |record| 
          if record[:label] == 'Number of individuals'
            identifications_count = record[:value].to_i
          end
        end

        hash.merge({
          identifications_count: identifications_count
        })
      end

      def self.populate_creator_name(hash)
        creator_name = hash[:observers][0][:user][:displayName] || ''
        hash.merge({
          creator_name: creator_name
        })
      end

    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions

      define! do
        deep_symbolize_keys
        populate_creator_name()
        unwrap :location, [:latitude, :longitude]
        rename_keys latitude: :lat
        rename_keys longitude: :lng

        rename_keys observedAt: :observed_at
        populate_unique_id()
        populate_identifications_count()
        populate_images()

        accept_keys [
          :unique_id,
          :creator_name,
          :lat,
          :lng,
          :observed_at,
          :identifications_count,
          :observation_url,
          :image_urls
        ]
      end
    end    
  end
end
