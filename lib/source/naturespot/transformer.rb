require_relative "../../common/transformer_functions.rb"

module Source
  class NatureSpot
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations
    
      ## We need to fetch ids which later are used to fetch scientific name
      def self.populate_species_id(hash)
        id = (hash[:attributes][:fld_16_00000847].present? ? hash[:attributes][:fld_16_00000847] :
              (hash[:attributes][:fld_16_00000848].present? ? hash[:attributes][:fld_16_00000848] :
              hash[:attributes][:fld_16_00000849]))
        if id.present?
          id = id.gsub('wd-', '')
        end

        hash.merge({
          species_id: id
        })
      end
    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions

      define! do
        unwrap :attributes, [:root_id, :image, :latitude, :longitude, :spotted_by_name, :created_at, :quantity]
        map_value :root_id, -> v { "ns-#{v}" }
        rename_keys root_id: :unique_id
        map_value :image, -> v { ["https://files.spotteron.com/images/spots/#{v}.jpg"] if v.present? }
        rename_keys image: :image_urls
        rename_keys latitude: :lat
        rename_keys longitude: :lng
        rename_keys spotted_by_name: :creator_name
        rename_keys quantity: :identifications_count
        rename_keys created_at: :observed_at
        populate_species_id()


        accept_keys [
          :unique_id,
          :creator_name,
          :image_urls,
          :lat,
          :lng,
          :observed_at,
          :identifications_count,
          :species_id
        ]
      end
    end    
  end
end
