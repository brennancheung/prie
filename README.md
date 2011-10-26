Postfix Ruby Interpreter for Embedding
======================================

Prie is designed to be embeddable in your applications and scripts to expose
a programatic interface to your code.  It is ideal for running untrusted 3rd
party code since it is interpreted and you only expose what you explicitly
enable.

The language itself should be familiar to anyone with experience with Forth,
Factor and even the common HP-48 calculator.  It is a stacked based language
designed to be simple and easy to write small snippets of code.

Use Cases
---------

- Conveniently interact with your models and code in your application.
- Expose a scripting shell within your application.
- A programmatic configuration tool for user.
- Provide users a mechanism for expressing complex logic.
- Let users programatically manipulate data in your application.

Installation
------------

    gem install prie

Usage
-----

    parser = Prie::MainParser.new
    result = parser.parse("1 2 3 + +")
    parser.execute_loop(result)

Testing
-------

    bundle exec rspec spec


Embedding Example
-----------------

    require "prie/main_parser"

    parser = Prie::MainParser.new
    while begin print "> " ; input = gets end
      input = input.strip
      result = parser.parse(input)
      parser.execute_loop(result)
      parser.stack.each_with_index {|obj, i| puts "#{i}:  #{obj}"}
      puts
    end 

Extending the API
-----------------

    require "prie/main_parser"

    class MyParser < MainParser
      def hello_world
        puts "hello world"
      end
    end