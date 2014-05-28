# encoding: utf-8
module Cobb
  class Gun
    class << self
      def fire(url, context = {})
        new(context).fire(url)
      end
    end
    
    def initialize(context)
      @context = Mash.new(context)
    end
    
    def fire(url)
      @url = url
      @victim = Victim.new(self, url)
      @raw = Cobb.web_client.get(url)
      
      mechanizm
      
      @victim
    ensure
      @url = nil
      @victim = nil
      @raw = nil
    end
    
    protected
    
    def mechanizm
      fail NotImplementedError, '#mechanizm should be implemented in descendants'
    end
    
    private

    # parsing helpers DSL
    
    attr_reader :url, :raw
    attr_reader :context
    
    def html
      require 'nokogiri'
      require 'nokogiri/more'
      @html ||= Nokogiri::HTML(raw, url)
    end

    def result(hash)
      @victim.merge_data!(hash)
    end
    
    def result_row(hash = nil, &block)
      @victim.row!(hash, &block)
    end
    
    def next_to(gun, url, context = {})
      @victim.next_order!(gun, url, context)
    end
  end
end
