module Prie
  class Lexer
    attr_accessor :input_text
    attr_accessor :cursor
    
    def initialize(input_text)
      # adding whitespace at the end makes it easy to not worry about the end-of-string (EOS) case
      self.input_text = input_text + " "
      self.cursor = 0
    end
    
    def next_char
      if cursor < input_text.length
        ch = input_text[cursor]
        self.cursor += 1
        ch
      else
        nil
      end
    end
  end
end