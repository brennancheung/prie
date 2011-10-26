# these will be pushed onto the parse vector
module Prie
  class Scope
    attr_accessor :scope
    attr_accessor :dirty

    def initialize
      @scope = {}
      @dirty = false
    end
    
    def to_s
      @scope.inspect
    end

    def []=(lval, rval)
      @scope[lval] = rval
      @dirty = true
    end

    def [](lval)
      @scope[lval]
    end

    def method_missing(sym, *args, &block)
      if sym =~ /=$/
        # setter

        # remove the trailing '=' to get the key in the scope
        @scope[sym[0..-2]] = args[0]
        @dirty = true
      else
        # getter
        @scope[sym.to_s]
      end
    end
  end
end
