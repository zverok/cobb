# encoding: utf-8
module Cobb
  class Victim
    def initialize(gun, url)
      @gun, @url = gun, url
      
      @data = Mash.new
      @datum = []
      @next_orders = []
    end
    
    attr_reader :gun, :url, :data, :datum, :next_orders
    
    def merge_data!(hash)
      current_data.merge!(hash)
    end
    
    def row!(hash = nil, &block)
      case
      when hash
        push_row(hash)
      when block
        @row_context = true
        push_row
        yield
        @row_context = false
      else
        fail 'Either hash or block inspected in row context'
      end
    end
    
    def next_order!(gun, url, context = {})
      @next_orders << Order.new(gun, url, context)
    end
    
    private
    
    def current_data
      @row_context ? current_row : data
    end
    
    def push_row(hash = nil)
      datum << Mash.new(hash || {})
    end
    
    def current_row
      datum.last
    end
  end
end
