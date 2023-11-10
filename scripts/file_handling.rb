#!/home/vagrant/.rvm/rubies/ruby-3.0.2/bin/ruby

begin
   aFile = File.new("input.txt", "w")
   if aFile
      aFile.syswrite("ABCDEF")
   else
      puts "Unable to open file!"
   end
rescue 
  puts "Error : $#{$!}"
else
  puts "No error in writiing file"
ensure
  aFile.close unless aFile.nil?
end


begin
  eval string
rescue SyntaxError, NameError => boom
  print "String doesn't compile: #{boom}"
rescue StandardError => bang
  print "Error running script: " + bang
end

