class DataSourceSerializer
  include JSONAPI::Serializer
  
  attributes :id, :name
end
