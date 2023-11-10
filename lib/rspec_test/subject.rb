class Person < ActiveModel::Base
  # include ActiveModel::::Validations

  # ActiveRecord provides attributes by default, but ActiveModel doesn't so you need to 
  # implement it yourself if you want to use subject.attributes in rspec.
  def self.attributes
    [:first_name, :last_name]
  end
  attr_accessor *self.attributes

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end

  

end
  