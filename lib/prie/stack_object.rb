# these will be pushed onto the parse vector
module Prie
  class StackObject
    attr_accessor :type
    attr_accessor :value
    
    class << self
      def infer_type(value)
        case value
        when FalseClass
          :boolean
        when Fixnum
          :integer
        when Float
          :float
        when String
          :string
        when Time
          :time
        when TrueClass
          :boolean
        end
      end
    end

    def initialize(type, value)
      self.type = type
      self.value = value
      
      # if it is a numeric value convert it automatically
      if self.type == :auto
        self.type = self.class.infer_type(value)
      elsif type == :word
        # convert words to number literals if possible
        self.type = :float if Float(value) rescue nil
        self.type = :integer if Integer(value) rescue nil # Integers are also valid floats so we need to do them last
        
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
        when :time
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
