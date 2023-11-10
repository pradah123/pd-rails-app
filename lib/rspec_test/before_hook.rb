class BeforeHook
  attr_accessor :message

  def initilize()
    puts "\nCreating a new instance of a class"
    @message = "Initializing before hook"
  end

  def update_message(new_message)
    @message = new_message
  end
end