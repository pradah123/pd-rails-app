require_relative '../lib/rspec_test/hello_world.rb'
require_relative '../lib/rspec_test/string_analyzer' 


RSpec.describe HelloWorld do 
  context "When testing the HelloWorld class" do 
     
     it "should say 'Hello World' when we call the say_hello method" do 
        hw = HelloWorld.new 
        message = hw.say_hello 
        expect(message).to eq "Hello World!"
     end

     it "should say 'Hello Prajakta' when we call the say_hello method with name" do 
      hw = HelloWorld.new 
      message = hw.say_hello("Prajakta")
      expect(message).to eq "Hello Prajakta!"
     end

     it "should not say 'Hello user' when we call the say_hello method without any name" do 
      hw = HelloWorld.new 
      message = hw.say_hello 
      expect(message).not_to eq "Hello Prajakta!"
   end
     
  end
end


describe StringAnalyzer do 
  context "With valid input" do 
      
    it "should detect when a string contains vowels" do
      st = StringAnalyzer.new
      test_string = "afgfg"
      expect(st.has_vowels? test_string).to be true 
    end

    it "should detect when a string doesn't contain vowels" do 
      st = StringAnalyzer.new
      test_string = "fgg"
      expect(st.has_vowels? test_string).to equal false 
    end
  end
end

