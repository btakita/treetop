module Treetop
  class SyntaxNode
    attr_reader :input, :interval, :nested_failures
    
    def initialize(input, interval, nested_failures = nil)
      @input = input
      @interval = interval
      @nested_failures = nested_failures
    end
    
    def text_value
      input[interval]
    end
    
    def success?
      true
    end
    
    def failure?
      false
    end
  end
end