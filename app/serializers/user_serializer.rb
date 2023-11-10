class UserSerializer
  include JSONAPI::Serializer
  attributes :organization_name, :email, :role, :status
end
