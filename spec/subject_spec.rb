# require_relative "../lib/rspec_test/subject.rb"
require 'rails_helper'
require 'person'

# Subject is instantiated lazily. That is, the implicit instantiation of the described class 
# or the execution of the block passed to subject doesn't happen until subject or 
# the named subject is referred to in an example. 
# If you want your explict subject to be instantiated eagerly 
# (before an example in its group runs), say subject! instead of subject.

# Expectations can be set on it implicitly (without writing subject or the name of a 
# named subject):

# describe A do
#   it { is_expected.to be_an(A) }
# end
# The subject exists to support this one-line syntax.
# https://stackoverflow.com/questions/38437162/whats-the-difference-between-rspecs-subject-and-let-when-should-they-be-used

describe "Person", type: :model do
  subject(:person_obj) { Person.new "John", "Kranski" }
  it ":without using subject", :first => true do
    a = "John"
    b = "Smith"
    person = Person.new a, b
    expect(person).to have_attributes(first_name: 'John') 
    expect(person.first_name).to eq 'John'
    expect(person.last_name).to_not eq 'Kranski'

    person_obj.last_name = "Smith"
    puts "Example 1"
    puts person.first_name
    puts person.last_name
    puts person_obj.last_name
  end

  it "should use subject" do
    puts "Example 2"
    expect(person_obj).to_not be nil
    expect(person_obj.last_name).to eq 'Kranski'
    puts person_obj.first_name
    puts person_obj.last_name
  end

  it "should validate presence of first_name" do 
    expect(person_obj).to have_attributes(first_name: 'John')
    expect(person_obj.attributes).to include(:first_name)
    # For following to work, need to change def attributes to def self.attributes in class (app/models/person.rb)
    # but above line will not work
    # expect(Person.attributes).to include(:last_name) 
  end

  
end
