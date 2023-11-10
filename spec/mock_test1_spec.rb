require_relative '../lib/rspec_test/mock_test_class_room' 

describe MockTestClassRoom do 
  it 'the list_student_names method should work correctly' do 
    student1 = double('student') 
    student2 = double('student') 
     
    #  Stubs
    # allow(student1).to receive(:name) { 'John Smith' } 
    # allow(student2).to receive(:name) { 'Jill Smith' }

    # Old way of writing stubs
    student1.stub(:name).and_return('John Smith')
    student2.stub(:name).and_return('Jill Smith')
     
    cr = MockTestClassRoom.new [student1, student2]
    expect(cr.list_student_names).to eq('John Smith,Jill Smith') 
  end 
end