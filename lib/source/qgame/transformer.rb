require_relative "../../common/transformer_functions.rb"

module Source
  class QGame
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations

      def self.populate_identifications_count(hash)
        # if expert comments present, then identifications count = num of expert comments
        identifications_count = hash[:expert_comments]&.count || 0
        if identifications_count < 1 && hash[:scientific_name].present?
          identifications_count = 1
        end
        hash.merge({
          identifications_count: identifications_count
        })
      end

      def self.populate_species_details(hash)
        scientific_name = hash[:category_name]
        common_name = hash[:category_name]
        if hash[:species].present?
          species = hash[:species]
          if species[:sname].present?
            scientific_name = species[:sname]
          end
          if species[:cname].present?
            common_name = species[:cname]
          end
        end
        hash.merge({
          scientific_name: scientific_name,
          common_name: common_name,
          accepted_name: scientific_name
        })
      end
    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions

      APP_ID = 'qgame'.freeze

      define! do
        deep_symbolize_keys
        map_value :id, -> v { "#{APP_ID}-#{v}" }
        rename_keys id: :unique_id
        populate_species_details()
        map_value :submitted_by_id, -> v { v.to_s }
        rename_keys submitted_by_id: :creator_id
        rename_keys submitted_by_name: :creator_name
        map_value :date, -> v { DateTime.parse(v).new_offset(0).strftime('%Y-%m-%d %H:%M') }
        rename_keys date: :observed_at
        # should be called after populate_species_details is called
        populate_identifications_count()
        map_value :images, -> images do
          images&.map { |image| image[:original] } || []
        end
        rename_keys images: :image_urls
        rename_keys bioScore: :bioscore
        accept_keys [
          :unique_id,
          :observed_at,
          :lat, 
          :lng,
          :scientific_name,
          :creator_id,
          :common_name,
          :creator_name,
          :image_urls,
          :accepted_name,
          :identifications_count,
          :bioscore
        ]                
      end
    end
  end
end
