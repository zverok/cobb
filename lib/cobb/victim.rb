# encoding: utf-8
module Cobb
  class Victim
    def initialize(gun, url)
      @gun, @url = gun, url
      
      @result = Mash.new
      @results = []
      @next_targets = []
    end
    
    attr_reader :gun, :url, :result, :results, :next_targets
    
    def merge_result!(hash)
      current_result.merge!(hash)
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
    
    def next_target!(gun, url, context = {})
      @next_targets << Target.new(gun, url, context)
    end
    
    private
    
    def current_result
      @row_context ? current_row : result
    end
    
    def push_row(hash = nil)
      results << Mash.new(hash || {})
    end
    
    def current_row
      results.last
    end
  end
end
