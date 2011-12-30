require "prie/parser"

module Prie
  class MainParser < Prie::Parser
    attr_accessor :words

    def run(input_text)
      result = self.parse(input_text) 
      self.execute_loop(result)
    end

    def return(input_text)
      self.run(input_text)
      @stack.pop
    end

    # Mechanism to allow words to be declared into the parser.
    # See the examples in 'initialize' for example usage.
    def def_word(declaration, automap_values=:both, &block)
      parts = declaration.split(' ')
      name = parts[0]
      state = :input
      input = []
      input_escapes = []
      output = []
      output_escapes = []

      parts[1..-1].each do |x|
        next if ['(', ')'].include?(x)
        if x == '--'
          state = :output
          next
        end
        escapes = []
        escaped = x[0] == '`'  # prefix stack types with '`' to get original object (as oposed to escaped value)
        value = escaped ? x[1..-1] : x
        if state == :input
          input.push(value)
          input_escapes.push(escaped)
        else
          output.push(value)
          output_escapes.push(escaped)
        end
      end

      self.words[name] = {
        :input => (input.map &:intern),
        :output => (output.map &:intern),
        :automap_values => automap_values,
        :input_escapes => input_escapes,
        :output_escapes => output_escapes,
        :block => block
      }

      true
    end

    def initialize
      super
      self.words ||= {}

      # Declaring new words takes the following format:
      # name ( input* -- output* ) {|*input, params| block code goes here}

      # name = name of the word
      # input = 0 or more input types
      # output = 0 or more output types

      # Note: the spaces around '(' and ')' are critical
      # Input parameters will be passed into the block
      # Output parameters will be pushed back onto the stack using the type(s) specified

      # By default, the input values are unwrapped and the output values wrapped.
      # Prefixing an input/output parameter with a '`' (backquote) will prevent unwrapping (input) and wrapping (output).
      # This frequently used when we don't know the object's type and want to preserve it.  It can also be used when
      # the output type(s) are not known until the block is executed.

      def_word("1+ ( scope string -- )") {|scope, field| scope[field] = StackObject.new(:integer, scope[field].value + 1) }
      def_word("1- ( scope string -- )") {|scope, field| scope[field] = StackObject.new(:integer, scope[field].value - 1) }
      def_word("<< ( scope string `any -- )") {|scope, string, value| scope[string] = value }
      def_word(">> ( scope string -- `any )") {|scope, string| scope[string] }
      def_word("= ( any any -- boolean )") {|a, b| a == b }
      def_word("!= ( any any -- boolean )") {|a, b| a != b }
      def_word("< ( any any -- boolean )") {|a, b| a < b }
      def_word("> ( any any -- boolean )") {|a, b| a > b }
      def_word("<= ( any any -- boolean )") {|a, b| a <= b }
      def_word(">= ( any any -- boolean )") {|a, b| a >= b }
      def_word("+ ( numeric numeric -- `numeric )") {|a, b| numeric_stack_object(a + b) }
      def_word("- ( numeric numeric -- `numeric )") {|a, b| numeric_stack_object(a - b) }
      def_word("* ( numeric numeric -- `numeric )") {|a, b| numeric_stack_object(a * b) }
      def_word("/ ( numeric numeric -- `numeric )") {|a, b| numeric_stack_object(a / b) }
      def_word("and ( boolean boolean -- boolean )") {|a, b| a && b }
      def_word("append ( array `any -- array )") {|arr, value| arr + [ value ] }
      def_word("append! ( array `any -- )") {|arr, value| arr.push( value ) }
      def_word("call ( array -- )") {|quot| execute_loop(quot) }
      def_word("clear ( -- )") { @stack = [] }
      def_word("concat ( array array -- array )") {|arr1, arr2| arr1 + arr2 }
      def_word("concat! ( array array -- )") {|arr1, arr2| arr1.concat(arr2) }
      def_word("count ( array -- integer )") {|arr| arr.count }
      def_word("debugger ( -- )") { debugger ; "you are entering the debugger" }
      def_word("dec ( scope string integer -- )") {|scope, field, amount| scope[field] = StackObject.new(:integer, scope[field].value - amount)}
      def_word("drop ( `any -- )") {}
      def_word("dup ( `any -- `any `any)") {|x| [ x, x ] }
      def_word("get-scope ( string -- scope )") {|scope_name| self.scopes[scope_name] }

      def_word("each ( array array -- )") do |seq, quot|
        seq.each do |x|
          @stack.push(x)
          execute_loop(quot)
        end
      end

      def_word("first ( array -- `any )") {|arr| arr.first }
      def_word("if ( boolean array array -- )") {|cond, tquot, fquot| execute_loop(cond ? tquot : fquot) }
      def_word("inc ( scope string integer -- )") {|scope, field, amount| scope[field] = StackObject.new(:integer, scope[field].value + amount) }
      def_word("join ( array string -- string )") {|arr, delim| arr.map(&:value).join(delim) }
      def_word("last ( array -- `any )") {|arr| arr.last }
      def_word("length ( array -- integer )") {|arr| arr.length }

      def_word("map ( array array -- array )") do |seq, quot|
        seq.inject([]) do |acc, x|
          @stack.push(x)
          execute_loop(quot)
          acc.push(@stack.pop)
        end
      end

      def_word("new-scope ( string -- )") {|scope_name| self.scopes[scope_name] = Prie::Scope.new}
      def_word("not ( boolean -- boolean )") {|bool| !bool }
      def_word("nth ( array integer -- `any )") {|arr, index| arr[index] }
      def_word("or ( boolean boolean -- boolean )") {|a, b| a || b }
      def_word("prepend ( array `any -- array )") {|arr, value| [ value ] + arr }
      def_word("prepend! ( array `any -- )") {|arr, value| arr.unshift( value ) }
      def_word("print ( string -- )") {|str| print str }
      def_word("puts ( string -- )") {|str| puts str }
      def_word("split ( string string -- array )") {|str, delim| str.split(delim).map {|x| StackObject.new(:string, x)} }
      def_word("str-concat ( string string -- string )") {|str1, str2| str1 + str2 }
      def_word("swap ( `any `any -- `any `any )") {|a, b| [b, a] }
      def_word("times ( integer array -- )") {|i, quot| i.times { execute_loop(quot) } }
      def_word("w ( string -- array )") {|str| str.split(' ').map {|x| StackObject.new(:string, x)} }
    end
      
    # You can create your own "vocabulary" for your parser by subclassing
    # Prie::Parser and adding your own "words" (API).
    def extended_base(word)
      word_hash = self.words[word.value]
      if word_hash
        # automatically grab the stack values
        stack_input_types = word_hash[:input]
        from_stack = from_stack(word.value, *stack_input_types)
        input_params = []
        if [:both, :input].include?(word_hash[:automap_values])
          from_stack.each_with_index do |x, i|
            input_params.push( word_hash[:input_escapes][i] ? x : x.value )
          end
        end

        output_types = word_hash[:output]
        output_params = word_hash[:block].call(*input_params)

        output_params = [ output_params ] if output_types.length == 1

        output_types.each_with_index do |value, i|
          value = word_hash[:output_escapes][i] ? output_params[i] : StackObject.new(output_types[i], output_params[i])
          @stack.push( value )
        end

        return true
      end

      case word.value
        when "accum>stack"
          # debugger
          # @stack.push(@parse_accums.last.last)
          true
        else
          return false
      end
      true
    end
    
    # Put this in a subclass to provide API hooks for 3rd party developers
    def extended_api(word)
      case word.value
        when "blah"
          true
        else
          raise "word '#{word.value}' not defined"
      end
    end
  end
end