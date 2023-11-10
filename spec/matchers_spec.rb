require_relative '../lib/rspec_test/string_analyzer' 

describe "An example of the comparison Matchers" do

  it "should show how the equality Matchers work" do 
    a = "test string" 
    b = a 
    
    # The following Expectations will all pass 
    expect(a).to eq "test string" 
    expect(a).to eql "test string" 
    expect(a).to be b 
    expect(a).to equal b 
 end

  it "should show how the comparison Matchers work" do
     a = 1
     b = 2
     c = 3		
     d = 'test string'
     
     # The following Expectations will all pass
     expect(b).to be > a
     expect(a).to be >= a 
     expect(a).to be < b 
     expect(b).to be <= b 
     expect(c).to be_between(1,3).inclusive #Passes when actual is <= min and >= max
     expect(b).to be_between(1,3).exclusive #Passes when actual is < min and > max	
    #  expect(c).to be_between(1,3).exclusive 

     expect(d).to match /TEST/i #Passes when actual matches a regular expression	
  end
  
end


describe "An example of the type/class Matchers" do
 
  it "should show how the type/class Matchers work for Numeric class" do
     x = 1 
     y = 3.14 
     z = 'test string' 
     
     # The following Expectations will all pass
     expect(x).to be_instance_of Fixnum # Passes when actual is an instance of the expected class.	
     expect(y).to be_kind_of Numeric #Passes when actual is an instance of the expected class or any of its parent classes.	
     expect(z).to respond_to(:length) #Passes when actual responds to the specified method.	
  end

  it "should show how the type/class matchers work for StringAnalyzer Class" do
    st = StringAnalyzer.new
    expect(st).to be_instance_of StringAnalyzer
    expect(st).to respond_to(:has_vowels?)
  end
end

describe "An example of the true/false/nil Matchers" do
  it "should show how the true/false/nil Matchers work" do
     x = true 
     y = false 
     z = nil 
     a = "test string" 
     
     # The following Expectations will all pass
     expect(x).to be true 
     expect(y).to be false 
     expect(a).to be_truthy #Passes when actual is not false or nil	
     expect(z).to be_falsey #Passes when actual is false or nil
     expect(z).to be_nil #Passes when actual is nil	
  end 
end

describe "An example of the error Matchers" do 
  it "should show how the error Matchers work" do 
     
     # The following Expectations will all pass
     #raise_error(ErrorClass)	Passes when the block raises an error of type ErrorClass.
     #Example - expect {block}.to raise_error(ErrorClass)
     expect { 1/0 }.to raise_error(ZeroDivisionError) 
     expect { 1/0 }.to raise_error("divided by 0") #raise_error("error message")	Passes when the block raise an error with the message “error message”.
     expect { 1/0 }.to raise_error("divided by 0", ZeroDivisionError) #raise_error(ErrorClass, "error message")	Passes when the block raises an error of type ErrorClass with the message “error message”
  end 
end