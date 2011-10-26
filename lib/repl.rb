# In order to get the lib folder to be included:
# RUBYLIB=. ruby repl.rb

require "prie/main_parser"

parser = Prie::MainParser.new
while begin print "> " ; input = gets end
  input = input.strip
  result = parser.parse(input)
  parser.execute_loop(result)
  parser.stack.each_with_index {|obj, i| puts "#{i}:  #{obj}"}
  puts
end 