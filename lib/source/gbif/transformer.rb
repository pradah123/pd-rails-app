require_relative "../../common/transformer_functions.rb"

module Source
  class GBIF
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations

      def self.populate_identifications_count(hash)
        identifications_count = hash[:individualCount] || 0
        if identifications_count < 1 && hash[:scientific_name].present?
          identifications_count = 1
        end
        hash.merge({
          identifications_count: identifications_count
        })
      end

      def self.populate_images(hash)
        images = hash[:media]
        image_urls = images.filter_map { |image| image[:identifier] if image[:type] == 'StillImage'}
        hash.merge({
          image_urls: image_urls
        })
      end

      def self.populate_unique_id(hash)
        unique_id = hash[:catalogNumber] || hash[:recordNumber] || hash[:identifier]
        unique_id = unique_id.gsub('questagame-', '')
        unique_id = unique_id.gsub(/\./, '')
         
        prefix = Source::GBIF.get_dataset_name(hash[:datasetKey])
        unique_id = "#{prefix}-#{unique_id}" if prefix.present? && prefix != 'ebird' ## We don't store prefix for ebird

        hash.merge({
          unique_id: unique_id
        })
      end
      def self.populate_creator_name(hash)
        creator_name = hash[:recordedBy]

        # For questagame, recordedBy contains a href tag e.g "<a href='https://bee.questagame.com/#/profile/31109?questagame_user_id=31109'>OriAM|questagame.com</a>",
        creator_name = hash[:recordedBy].match(/<a.*?>(.*?)[\|<]/).captures[0] if creator_name =~ /<a /
        hash.merge({
          creator_name: creator_name
        })
      end
    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions

      define! do
        populate_unique_id()
        rename_keys scientificName: :scientific_name
        copy_keys scientific_name: :accepted_name
        rename_keys vernacularName: :common_name
        populate_creator_name()
        populate_images()
        rename_keys decimalLongitude: :lng
        rename_keys decimalLatitude: :lat
        rename_keys eventDate: :observed_at
        populate_identifications_count()
        
        accept_keys [
          :unique_id,
          :scientific_name,
          :common_name,
          :accepted_name,
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
