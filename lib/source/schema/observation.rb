require 'dry/schema'

module Source
  module Schema
    ObservationSchema = Dry::Schema.Params do
      required(:unique_id).filled(:string)
      required(:lat).filled(:float)
      required(:lng).filled(:float)
      required(:observed_at).filled(:string)
      required(:identifications_count).filled(:integer)
      
      optional(:image_urls).maybe(array[:string])
      optional(:common_name).maybe(:string)
      optional(:scientific_name).maybe(:string)
      optional(:accepted_name).maybe(:string)
      optional(:creator_name).maybe(:string)
      optional(:creator_id).maybe(:string)
      optional(:bioscore).maybe(:float)
    end
  end
end
