require_relative "../lib/rspec_test/helper.rb"

describe Dog do
  def can_walk_the_dog(good_or_not)
    dog = Dog.new(good_or_not)
    dog.walk_dog()
    return dog
  end

  it "should walk the good dog" do
    dog  = can_walk_the_dog(true)
    expect(dog.good_dog).to be true
    expect(dog.has_been_walked).to be true
  end

  it "should walk the bad dog" do
    dog  = can_walk_the_dog(false)
    expect(dog.good_dog).to be false
    expect(dog.has_been_walked).to be true
  end
end
