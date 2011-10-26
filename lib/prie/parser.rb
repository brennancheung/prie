require "prie/lexer"
require "prie/scope"
require "prie/stack_object"

module Prie
  class Parser
    attr_accessor :stack
    attr_accessor :scopes
    
    DEFAULT_PARSE_WORDS = {
      '[' => '"]" parse-until accum>stack'
    }

    attr_accessor :stack_effects

    def initialize
      # Each nested parsing word has its own environment.  In order to do this we need stacks of lexers and stacks of parse_accums
      @parse_accums = []  # A stack holding the stacks of results from parsing.  Starts with 1 empty stack
      @lexers = []
      @parse_words = DEFAULT_PARSE_WORDS.clone
      @stack = []  # This is the "stack" that the execution environment uses.
      @stack_effects = {}
      @scopes = {}
    end

    def clear
      @stack = []      
    end

    # when we have some parsed input add it to the parse stack (similar in concept to adding to a parse tree)
    def accum(word)
      @parse_accums.last.push(word)
    end
    
    def parse(input)
      @lexers.push Lexer.new(input)
      
      @parse_accums.push([]) # make a new accumulator
      parse_loop
      result = @parse_accums.pop
      
      @lexers.pop
      
      # puts result.join(' ')
      # result.each {|x| puts "#{x} (#{x.type})"}
      result
    end
    
    def next_char
      @lexers.last.next_char
    end
    
    def parse_one
      result = scan
      if result
        if result.type == :word && @parse_words.member?(result.value)
          result.type == :parsing_word
          # puts "parsing word #{result.value} => #{@parse_words[result.value]}"
          immediate_code = parse(@parse_words[result.value])
        
          # puts "I am executing a parsing word with lexer as: #{@lexers.last.inspect}"
          execute_loop(immediate_code)

          # puts "should execute #{immediate_code.join(' ')}"
        else
          if result.type == :word
            if result.value == "t"
              result.type = :boolean
              result.value = true
            elsif result.value == "f"
              result.type = :boolean
              result.value = false
            end
          end
          accum(result)
        end
      end
    end

    def parse_loop
      true while parse_one
    end
    
    def scan
      # returns the next word or string in the input
      state = :whitespace
      token = ""
      
      while ch = next_char      
        # puts "#{ch}, #{state}, @cursor=#{@cursor}, token = #{token}"

        if state == :whitespace
          if ch == '"'
            state = :string
          elsif ch =~ /\S/ # not whitespace
            token = ch
            state = :token
          else
            # whitespace, just advance to next ch
          end
        elsif state == :string
          if ch == '"'
            return StackObject.new(:string, token)
          else
            token += ch
          end
        elsif state == :token
          if ch =~ /\S/ # not whitespace
            token += ch
          else
            state = :whitespace
            return StackObject.new(:word, token)
          end
        end
      end
      
      return false # we reached the End-of-String (EOS)
    end
    
    # Ex: from_stack(:my_word, :string, :integer, :string)
    def from_stack(word, *args)
      valid = true
      
      result = []
      args.reverse.each_with_index do |arg, i|
        obj = @stack.pop
        valid = case arg
          when :any
            obj
          when :numeric
            true if [:float, :integer].member?(obj.type)
          else
            true if arg == obj.type
          end
        result.push(obj)
        # puts "comparing #{arg} with #{@stack[idx].type} with idx #{i}"
      end
      
      raise "invalid stack, \"#{word}\" expects #{p args}" unless valid
      
      return result.reverse
    end
    
    # executes a single literal / word / parsing word
    def execute(word)
      # literals get pushed to the stack immediately
      case word.type
        when :array
          @stack.push(word)
        when :string
          @stack.push(word)
        when :integer
          @stack.push(word)
        when :float
          @stack.push(word)
        when :boolean
          @stack.push(word)
        when :word
          # words get executed
          case word.value
            when "parse-until"
              delimiter = from_stack(:parse_until, :string).first.value
              @parse_accums.push([])
              begin
                result = parse_one
                raise "expecting #{delimiter} but never found" unless result
              end until @parse_accums.last.last.value == delimiter
              parsed_part = @parse_accums.pop
              parsed_part.pop
              accum(StackObject.new(:array, parsed_part))
            when "scan"
              current_stack.push(scan)
            else
              if word.value =~ /^@/
                # use the scope accessor reader macro
                scope_str = word.value[1..-1]

                # '.' is standard OO notation for nested scopes
                scopes = scope_str.split(".")
                value = scopes.inject(@scopes) {|cur_scope, rval| cur_scope[rval]}

                if value.instance_of?(Prie::Scope)
                  @stack.push(StackObject.new(:scope, value))
                else
                  @stack.push(value)
                end
              else
                # the user defined API (vocabulary) is defined elsewhere
                extended_base(word) || extended_api(word)
              end
          end
        when :parsing_word
          # parsing words are similar to macros in other languages
          
          # make a new parse vector
          parse(@parsing_words[word.value])
          
          # parse the parsing word
          
          # return the accum
          
          # start executing in the new context
          # return resultant parse vector and add it to the previous parse vector
      end
    end
    
    # returns either a float or an integer stack object
    def numeric_stack_object(value)
      type = :float if Float(value) rescue nil
      type = :integer if Integer(value) rescue nil # Integers are also valid floats so we need to do them last
      StackObject.new(type, value)
    end

    # goes through the parse vector
    def execute_loop(words)
      words.each {|word| execute(word)}
    end
    
    # Put this in a subclass to provide additional extended "words"
    def extended_base(word)
      return false # not found
      return true # if the word is found
    end
    
    # Put this in a subclass to provide API hooks for 3rd party developers
    def extended_api(word)
      case word.value
        when "custom-word-here"
          true
        else
          raise "word '#{word.value}' not defined"
      end
    end
  end
end
