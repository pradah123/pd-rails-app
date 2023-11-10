require_relative "../lib/rspec_test/subject.rb"

describe Person.new 'John', 'Smith' do # Defining subject in describe itself
  it { is_expected.to have_attributes(first_name: 'John') } 
  it { is_expected.to have_attributes(last_name: 'Smith') }
  
end