require 'dry/validation'

module AppSchema
  module Pagination
    def self.extended(object)
      super(object)
      # https://medium.com/rubycademy/ruby-instance-eval-a49fd4afa268
      # In Ruby, when we want to add a method to an instance we can use the 
      # BasicObject#instance_eval method. This method accepts a String or a block as argument
      object.instance_eval do
        optional(:offset).filled(:integer, gteq?: 0)
        optional(:limit).filled(:integer, gt?: 0)
      end
    end
  end
end
