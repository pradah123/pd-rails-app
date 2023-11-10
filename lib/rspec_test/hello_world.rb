class HelloWorld

  def say_hello(name = nil)
    if name
     "Hello #{name}!"
    else
      "Hello World!"
    end
  end
  
end
