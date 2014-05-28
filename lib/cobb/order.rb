# encoding: utf-8
module Cobb
  class Order
    def initialize(gun, url, context)
      @gun, @url, @context = gun, url, Mash.new(context)
    end
    
    attr_reader :gun, :url, :context
    
    def perform!
      gun.fire(url, context)
    end
    
    def inspect
      if context.empty?
        "#<#{self.class.name}: #{gun}.fire(#{url})>"
      else
        "#<#{self.class.name}: #{gun}.fire(#{url}) with #{context.inspect}>"
      end
    end
  end
end
