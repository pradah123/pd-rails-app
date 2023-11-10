class ParticipationSerializer
  include JSONAPI::Serializer
  attributes :observations_count, :identifications_count, :people_count,
             :species_count, :physical_health_score,  :mental_health_score

  ## Commenting below code as we are not using it anywhere in the project
  # attribute :data_source_ids do |object|
  #   object.data_sources.pluck :id
  # end

  attribute :top_species, if: Proc.new { |record, params|
    !params.blank? && params[:include_top_species] == true
  } do |object|
      object.get_top_species(10).map { | species |
        {
          name:  species[0],
          count: species[1]
        }}
  end

  attribute :top_observers, if: Proc.new { |record, params|
    !params.blank? && params[:include_top_people] == true
  } do |object|
      object.get_top_people(10).map { | species |
        {
          name:  species[0],
          count: species[1]
        }}
  end

end
