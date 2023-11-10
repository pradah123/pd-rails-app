require 'dry-struct'

module Types
  include Dry.Types()
end

module AppStruct
  class Pagination < Dry::Struct
    attribute? :offset, Types::Coercible::Integer.default(0)
    attribute? :limit, Types::Coercible::Integer.default(20)
  end
end
