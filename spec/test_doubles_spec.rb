require_relative '../lib/rspec_test/test_doubles.rb' 

describe ClassRoom do 
  it 'the list_student_names method should work correctly' do 
     student1 = double('student') 
     student2 = double('student')
     
     allow(student1).to receive(:name) { 'John Smith'}
    #  The value provided to and_return() defines the return value of the stubbed method. 
    #  The use of and_return() is optional, and if you don’t have it, 
    #  the stubbed method will be set to return nil.
     allow(student2).to receive(:name).and_return('Jill Smith')

     cr = ClassRoom.new [student1, student2]
     expect(cr.list_student_names).to eq('John Smith,Jill Smith') 
  end 
end