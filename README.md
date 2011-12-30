Postfix Ruby Interpreter for Embedding
======================================

Prie is designed to be embeddable in your applications and scripts to expose
a programatic interface to your code.  It is ideal for running untrusted 3rd
party code since it is interpreted and you only expose what you explicitly
enable.

The language itself is modeled after [Factor](http://factorcode.org) but should
also be familiar to anyone with experience with Forth or even reverse polish
notation (RPN) on the HP-48 calculator.  It is a stacked based language designed
to be simple and easy to write small snippets of code.

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

 ```ruby
 parser = Prie::MainParser.new
 result = parser.parse("1 2 3 + +")
 parser.execute_loop(result)
 ```


Embedding Example
-----------------
  ```ruby
  require "prie/main_parser"
   parser = Prie::MainParser.new
  while begin print "> " ; input = gets end
    input = input.strip
    result = parser.parse(input)
    parser.execute_loop(result)
    parser.stack.each_with_index {|obj, i| puts "#{i}:  #{obj}"}
    puts
  end 
  ```

CLI / REPL
----------

`lib/repl.rb` contains a simple REPL that you can use to experiment and learn with.

It might be useful to run it with [rlwrap](http://utopia.knoware.nl/~hlub/uck/rlwrap/#rlwrap) to
better editing support.

  ```bash
  cd lib
  RUBYLIB=. rlwrap ruby repl.rb
  ```

Extending the API
-----------------

To add your own API extend `MainParser`, or just `Parser` if you don't want the existing minimal API.
Then use `def_word`.  See below for an explanation of how to use it.

  ```ruby
  require "prie/main_parser"
  class MyParser < MainParser
    def initialize
      super
      def_word("greeting ( string -- )") { |name| puts "hello #{name}" }
    end
  end
  ```

`def_word` adds a _word_ to the parser's _vocabulary_.  It takes a string for the word's _stack declaration_
and a block for the actual code.  Words can consist of any non-whitespace character (including sepcial symbols).

The _stack declaration_ is similar to function prototype in C.  The first part is the name of the _word_.
After that will be the input parameters inside of `()`.  Input and output params are separated by `--`.  Please
be conscious of the space around the parens and `--`; they are required.

The block receives its inputs from the stack according to what was specified in the _stack declaration_.

Let's take a look at the above example.

  def_word("greeting ( string -- )") { |name| puts "hello #{name}" }

We define a new word `greeting` that takes a single `string` as input and has no output parameters.
In the _stack delcaration_ we must specify the _type_ (see `stack_object.rb` for a list of types) and in the block
we can name the parameter whatever we want.

Let's define another word that takes multiple inputs and has an output.

  def_word("sum ( integer integer -- integer )") {|a, b| a + b}

Now let's take a look at `dup` to see how we can return multiple values and learn about escaping.

  def_word("dup ( ``any -- ``any ``any)") {|x| [ x, x ] }

`dup` takes a single input of any type and returns 2 of the same.

Normally inputs and outputs are wrapped in a `StackObject` automatically for us.  A `StackObject` contains a type
and a value.  Most of the time we are only dealing with the values.  What looks like an _integer_ or a _string_ on
the stack is actually wrapped inside of a `StackObject`.  We use ` `` ` symbol (backquote) to control escaping.
For input params it will pass in the entire StackObject and just its value.  For output params it will take what
the block returns and wrap it inside of a `StackObject` with the corresponding _type_ from the stack declaration output
params.

We can also return multiple values by simply wrapping the return value in an array.

Stack declarations are validated before the block is called.  If the type does not match what is on the stack an
exception will be thrown.  `any` is a special type that means accept anything.

Please see `main_parser.rb` for further examples on how to create new words.
