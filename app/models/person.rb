class Person 
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::AttributeMethods

  attr_accessor :first_name, :last_name

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end

  # ActiveRecord provides attributes by default, but ActiveModel doesn't so you need to 
  # implement it yourself if you want to use subject.attributes in rspec.
  def attributes
    { first_name: @first_name,
      last_name: @last_name }
  end



  

end
  