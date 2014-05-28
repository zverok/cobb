# encoding: utf-8
module Cobb
  class Gun
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
      #if @current_row
        #@current_row.merge!(hash)
      #else
        @victim.data.merge!(hash)
      #end
    end

  end
end
