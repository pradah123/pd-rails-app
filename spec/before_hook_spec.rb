require_relative '../lib/rspec_test/before_hook.rb'
describe BeforeHook do
  before(:each) do
    @simple_class = BeforeHook.new
  end

  it "should have an initial message", :first => true do
    expect(@simple_class).to_not be nil
    expect(@simple_class.message).to be_nil

    puts "first example"
    @simple_class.message = "Updating message"
    expect(@simple_class.message).to_not be "hello"
    # puts @simple_class.message2
  end

  it "should update the message", :second => true do
    expect(@simple_class).to_not be nil
    # expect(@simple_class.message).to_not be nil # This should work if use before(:all)
    puts "second example"
    puts @simple_class.message # This should display "Updating message" set in first example if we use before(:all)
    @simple_class.update_message("new message")
    puts @simple_class.message
    expect(@simple_class.message).to eq "new message"
    expect(@simple_class.message).to_not be "hello"
  end
end