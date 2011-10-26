# these will be pushed onto the parse vector
module Prie
  class StackObject
    attr_accessor :type
    attr_accessor :value
    
    def initialize(type, value)
      self.type = type
      self.value = value
      
      # if it is a numeric value convert it automatically
      if type == :word
        # puts "int? #{value}"
        self.type = :float if Float(value) rescue nil
        self.type = :integer if Integer(value) rescue nil # Integers are also valid floats so we need to do them last
        # puts "type = #{self.type}"
        
        self.value = Float(value) if self.type == :float
        self.value = Integer(value) if self.type == :integer
      end
    end
    
    def to_s
      case self.type
        when :array
          "[ #{self.value.join ' '} ]"
        when :boolean
          self.value ? 't' : 'f'
        when :float
          self.value.to_s
        when :integer
          self.value.to_s
        when :scope
          self.value.to_s
        when :string
          "\"#{self.value}\""
        else
          self.value
      end
    end
  end
end
