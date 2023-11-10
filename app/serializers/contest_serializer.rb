class ContestSerializer
  include JSONAPI::Serializer
  attributes :title, :description, :status, :starts_at, :ends_at
end
