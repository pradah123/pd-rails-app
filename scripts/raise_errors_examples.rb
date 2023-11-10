#!/home/vagrant/.rvm/rubies/ruby-3.0.2/bin/ruby 

myNames = [1,2,3]; i = 4;

#if i >= myNames.size
#  raise IndexError, "#{i} >= size (#{myNames.size})"
#end

#str = "asdkadkasjdklasjdj"
#if str.length > 10



def divide_by_zero
begin
  sleep 10
  b = 5/0
rescue Exception
  STDERR.puts "Can't divide by 0"
  #raise ArgumentError, "Can't divide by 0", caller[0..-2]
end
#the following code removes two routines from the backtrace.
end


def test_nested_routines_skip

    divide_by_zero
end

test_nested_routines_skip

