require "prie/parser"

module Prie
  class MainParser < Prie::Parser
    def run(input_text)
      result = self.parse(input_text) 
      self.execute_loop(result)
    end

    def return(input_text)
      self.run(input_text)
      @stack.pop
    end
      
    # You can create your own "vocabulary" for your parser by subclassing
    # Prie::Parser and adding your own "words" (API).
    def extended_base(word)
      case word.value
        when "1+"
          scope, lval = from_stack(:inc, :scope, :string)
          old_value = scope.value[lval.value.to_s].value
          scope.value[lval.value.to_s] = StackObject.new(:integer, old_value + 1)
        when "1-"
          scope, lval = from_stack(:inc, :scope, :string)
          old_value = scope.value[lval.value.to_s].value
          scope.value[lval.value.to_s] = StackObject.new(:integer, old_value - 1)
        when "<<"
          scope, lval, rval = from_stack(:scope_setter, :scope, :string, :any) 
          scope.value[lval.value.to_s] = rval
        when ">>"
          scope, lval = from_stack(:scope_setter, :scope, :string) 
          @stack.push(scope.value[lval.value.to_s])
        when "="
          # stack_effect_for('=', :equals, [:any, :any], :boolean)
          # self.stack_effects['='] = "equals: any any -- boolean"
          a, b = from_stack(:equals, :any, :any).map(&:value)
          @stack.push(StackObject.new(:boolean, a==b))
        when "!="
          # stack_effect_for('=', :equals, [:any, :any], :boolean)
          # self.stack_effects['='] = "equals: any any -- boolean"
          a, b = from_stack(:equals, :any, :any).map(&:value)
          @stack.push(StackObject.new(:boolean, a!=b))
        when "<"
          a, b = from_stack(:less_than, :numeric, :numeric).map(&:value)
          @stack.push(StackObject.new(:boolean, a<b))
        when ">"
          a, b = from_stack(:greater_than, :numeric, :numeric).map(&:value)
          @stack.push(StackObject.new(:boolean, a>b))
        when "<="
          a, b = from_stack(:greater_than_or_equal, :numeric, :numeric).map(&:value)
          @stack.push(StackObject.new(:boolean, a<=b))
        when ">="
          a, b = from_stack(:less_than_or_equal, :numeric, :numeric).map(&:value)
          @stack.push(StackObject.new(:boolean, a>=b))
        when "+"
          a, b = from_stack(:+, :numeric, :numeric).map(&:value)
          @stack.push(numeric_stack_object(a + b))
        when "-"
          a, b = from_stack(:-, :numeric, :numeric).map(&:value)
          @stack.push(numeric_stack_object(a - b))
        when "*"
          a, b = from_stack(:*, :numeric, :numeric).map(&:value)
          @stack.push(numeric_stack_object(a * b))
        when "/"
          a, b = from_stack(:/, :numeric, :numeric).map(&:value)
          @stack.push(numeric_stack_object(a / b))
        when "accum>stack"
          # debugger
          # @stack.push(@parse_accums.last.last)
          true
        when "and"
          b1, b2 = from_stack(:and, :boolean, :boolean).map(&:value)
          @stack.push(StackObject.new(:boolean, b1 && b2))
        when "append"
          arr, element = from_stack(:append, :array, :any)
          new_arr = arr.value + [ element ]
          @stack.push(StackObject.new(:array, new_arr))
        when "append!"
          arr, element = from_stack(:append, :array, :any)
          arr.value.push(element)
        when "call"
          obj = from_stack(:call, :array).first.value
          execute_loop(obj)
        when "clear"
          @stack = []
        when "concat"
          arr1, arr2 = from_stack(:concat, :array, :array).map(&:value) 
          new_arr = arr1 + arr2
          @stack.push(StackObject.new(:array, new_arr))
        when "concat!"
          arr1, arr2 = from_stack(:concat, :array, :array).map(&:value) 
          arr1.concat(arr2)
        when "count"
          arr = from_stack(:length, :array).first.value
          @stack.push(StackObject.new(:integer, arr.length))
        when "debugger"
          debugger
          "you are entering the debugger"
        when "dec"
          scope, lval, rval = from_stack(:dec, :scope, :string, :integer)
          old_value = scope.value[lval.value.to_s].value
          scope.value[lval.value.to_s] = StackObject.new(:integer, old_value - rval.value)
        when "drop"
          from_stack(:drop, :any)
        when "dup"
          last_object = from_stack(:dup, :any).first
          @stack.push(last_object)
          @stack.push(last_object)
        when "each"
          arr, quot = from_stack(:map, :array, :array).map(&:value)
          tmp_accum = []
          arr.each do |x|
            @stack.push(x)
            execute_loop(quot)
            tmp_accum.push(@stack.pop)
          end
          tmp_accum.each {|x| @stack.push(x)}
        when "first"
          arr = from_stack(:nth, :array).first.value
          @stack.push(arr.first)
        when "get-scope"
          scope_name = from_stack(:get_scope, :string).first.value
          scope_value = self.scopes[scope_name]
          @stack.push(StackObject.new(:scope, scope_value))
        when "if"
          cond, true_quot, false_quot = from_stack(:if, :boolean, :array, :array)
          bool = cond.value
          execute_loop(bool ? true_quot.value : false_quot.value)
        when "inc"
          scope, lval, rval = from_stack(:inc, :scope, :string, :integer)
          old_value = scope.value[lval.value.to_s].value
          scope.value[lval.value.to_s] = StackObject.new(:integer, old_value + rval.value)
        when "join"
          strs, delim = from_stack(:join, :array, :string).map(&:value)
          str = strs.map(&:value).join(delim)
          @stack.push(StackObject.new(:string, str))
        when "last"
          arr = from_stack(:nth, :array).first.value
          @stack.push(arr.last)
        when "length"
          arr = from_stack(:length, :array).first.value
          @stack.push(StackObject.new(:integer, arr.length))
        when "map"
          arr, quot = from_stack(:map, :array, :array).map(&:value)
          new_arr = arr.inject([]) do |acc, x|
            @stack.push(x)
            execute_loop(quot)
            acc.push(@stack.pop)
          end
          @stack.push(StackObject.new(:array, new_arr))
        when "new-scope"
          name = from_stack(:new_scope, :string).first.value
          self.scopes[name] = Prie::Scope.new
        when "not"
          bool = from_stack(:not, :boolean).map(&:value).first
          @stack.push(StackObject.new(:boolean, !bool))
        when "nth"
          arr, index = from_stack(:nth, :array, :integer).map(&:value)
          @stack.push(arr[index])
        when "or"
          b1, b2 = from_stack(:and, :boolean, :boolean).map(&:value)
          @stack.push(StackObject.new(:boolean, b1 || b2))
        when "prepend"
          arr, element = from_stack(:prepend, :array, :any)
          new_arr = [ element ] + arr.value
          @stack.push(StackObject.new(:array, new_arr))
        when "prepend!"
          arr, element = from_stack(:append, :array, :any)
          arr.value.unshift(element)
        when "print"
          str = from_stack(:print, :string).first.value
          print str
        when "puts"
          str = from_stack(:print, :string).first.value
          puts str
        when "split"
          str, delim = from_stack(:split, :string, :string).map(&:value)
          strs = str.split(delim).map {|x| StackObject.new(:string, x)}
          @stack.push(StackObject.new(:array, strs))
        when "str-concat"
          a, b = from_stack(:append, :string, :string).map(&:value)
          @stack.push(StackObject.new(:string, a + b))
        when "swap"
          a, b = from_stack(:swap, :any, :any)
          @stack.push(b)
          @stack.push(a)
        when "times"
          i, quot = from_stack(:times, :integer, :array).map(&:value)
          i.times do
            execute_loop(quot)
          end
        when "w"
          text = from_stack(:w, :string).first.value
          strs = text.split(" ").map {|x| StackObject.new(:string, x)}
          @stack.push(StackObject.new(:array, strs))
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