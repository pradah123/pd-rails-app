# frozen_string_literal: true

require 'dry/matcher/result_matcher'
require 'dry/monads'
require 'dry/monads/do'

# Refer following to understand the working of this class
# https://veerpalbrar.github.io/blog/2021/11/26/Include,-Extend,-and-Prepend-In-Ruby
# https://juzer-shakir.medium.com/accessing-module-in-root-in-ruby-8eb46dbb38e1

module Service
  module Application
    module ClassMethods
      def call(params, &block)
        # Executed InstanceMethods execute method since it is prepended
        service_outcome = new.execute(params)
        if block_given?
          # Refer https://github.com/dry-rb/dry-matcher/blob/main/lib/dry/matcher/result_matcher.rb
          # to understand how ResultMatcher works
          Dry::Matcher::ResultMatcher.call(service_outcome, &block)
        else
          service_outcome
        end
      end
    end

    module InstanceMethods
      include Dry::Monads[:result, :do]

      def execute(params)
        # Refer https://dry-rb.org/gems/dry-monads/1.3/do-notation/
        # to understand working of the following line
        yield validate_params(params)
        super(params)
      end

      def validate_params(params)
        if self.class.constants.include? :ValidationSchema
          validation_outcome = self.class.const_get(:ValidationSchema).call(params)
          return Failure(format(validation_outcome)) if validation_outcome.failure?
        end
        Success(params)
      end

      private

      def format(schema_error)
        schema_error.errors(full: true)
                    .to_h
                    .values
                    .flatten
                    .join('\n')
      end
    end

    # Whenever a class includes a module, 
    # it runs the self.included callback on the module
    def self.included(klass)
      # With prepend, the module is added before the class in the ancestor chain. 
      # This means ruby will look at the module to see if an instance method is 
      # defined before checking if it is defined in the class.
      klass.prepend InstanceMethods
      # When a class extend’s a module, it adds the module methods as class methods 
      # on the class.
      klass.extend ClassMethods
    end
  end
end
