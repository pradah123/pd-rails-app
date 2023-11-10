class ObservationSerializer
    include JSONAPI::Serializer

    attributes :id, :lat, :lng, :identifications_count, :address, :creator_id, :bioscore
    belongs_to :data_source

    attribute :creator_name do |object|
      object.creator_name ||  ''
    end
    attribute :scientific_name do |object|
        object.scientific_name || ''
    end

    attribute :common_name do |object|
        object.common_name || ''
    end

    attribute :accepted_name do |object|
      object.accepted_name || ''
    end

    attribute :created_at do |object|
      object.created_at_utc
    end

    attribute :observed_at do |object|
      object.observed_at_utc
    end

    attribute :updated_at do |object|
      object.updated_at_utc
    end

    attribute :data_source do |object|
      object.data_source.name
    end

    attribute :category do |object|
      # If data source of observation is questagame, check if scientific_name matches with any category name in _category_mapping.json
      # if matches then return scientific name as category name
      # else get category name from taxonomy details of associated taxonomy_id
      if object.data_source.name == 'qgame' &&
          !Utils.get_category_rank_name_and_value(category_name: object.scientific_name).blank?
        object.scientific_name
      else
        object.taxonomy&.get_category_name
      end
    end

    attribute :images do |object|
      object.observation_images
    end
end
